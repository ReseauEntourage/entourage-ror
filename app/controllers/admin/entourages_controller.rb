module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update, :moderator_read, :moderator_unread, :message, :sensitive_words, :sensitive_words_check]
    before_filter :ensure_moderator!, only: [:message]

    def index
      per_page = params[:per] || 50

      # workaround for the 'null' option
      if params.dig(:q, :display_category_eq) == EntouragesHelper::NO_CATEGORY
        ransack_params = params[:q].dup
        ransack_params.delete(:display_category_eq)
        ransack_params.merge!(display_category_null: 1)
      else
        ransack_params = params[:q]
      end

      community = params[:community] || :entourage
      group_types = (params[:group_type] || 'action,outing').split(',')

      @q = Entourage
        .where(group_type: group_types, community: community)
        .with_moderation

      main_moderator = ModerationServices.moderator(community: current_user.community)
      if current_user != main_moderator && (params.keys - ['controller', 'action']).none? && current_user.roles.include?(:moderator)
        params[:moderator_id] = current_user.id
      end

      if params[:moderator_id] == 'none'
        @q = @q.where(entourage_moderations: {moderator_id: nil})
      elsif params[:moderator_id] == 'any'
        # default
      elsif params[:moderator_id].present?
        @q = @q.where(entourage_moderations: {moderator_id: params[:moderator_id]})
      else
        # make it explicit
        params[:moderator_id] = 'any'
      end

      @q = @q.ransack(ransack_params)

      @entourages =
        @q.result
        .page(params[:page])
        .per(per_page)
        .with_moderator_reads_for(user: current_user)
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated,
          moderator_reads is null and entourages.created_at >= now() - interval '1 week' as unread
        ))
        .group("entourages.id, moderator_reads.id, entourage_moderations.id")

      # I changed the implementation here. This option is to temporarily
      # go back to the old one if there is a bug.
      if params[:old_query] == '1'
        @entourages = @entourages
          .joins("left join conversation_messages on conversation_messages.messageable_type = 'Entourage' and conversation_messages.messageable_id = entourages.id")
          .order(%(
            case
            when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
            when max(conversation_messages.created_at) >= moderator_reads.read_at then 1
            else 2
            end
          ))
      else
        @entourages = @entourages
          .joins(%(
            left join chat_messages
              on chat_messages.messageable_type = 'Entourage'
             and chat_messages.messageable_id = entourages.id
          ))
          .joins(%(
            left join join_requests
              on join_requests.joinable_type = 'Entourage'
             and join_requests.joinable_id = entourages.id
             and join_requests.status in ('pending', 'accepted')
             and join_requests.message <> ''
          ))
          .order(%(
            case
            when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
            when greatest(max(chat_messages.created_at), max(join_requests.requested_at)) >= moderator_reads.read_at then 1
            else 2
            end
          ))
      end

      @entourages = @entourages
        .order("created_at DESC")
        .to_a

      @entourages = Kaminari.paginate_array(@entourages, total_count: @q.result.count).page(params[:page]).per(per_page)
      entourage_ids = @entourages.map(&:id)
      @member_count =
        JoinRequest
          .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :accepted)
          .joins(:user)
          .merge(User.where(admin: false))
          .group(:joinable_id)
          .count
      @member_count.default = 0

      @requests_count =
        JoinRequest
          .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :pending)
          .group(:joinable_id)
          .pluck(%(
            joinable_id,
            count(*),
            count(case when updated_at <= now() - interval '48 hours' then 1 end)
          ))
      @requests_count = Hash[@requests_count.map { |id, total, late| [id, { total: total, late: late }]}]
      @requests_count.default = { total: 0, late: 0 }

      @reminded_users =
        Experimental::PendingRequestReminder
          .recent
          .where(user_id: @entourages.map(&:user_id))
          .pluck('distinct user_id')
      @reminded_users = Set.new(@reminded_users)

      @message_count =
        ConversationMessage
          .with_moderator_reads_for(user: current_user)
          .where(messageable_type: :Entourage, messageable_id: entourage_ids)
          .group(:messageable_id)
          .select(%{
            messageable_id,
            sum(case when conversation_messages.content <> '' then 1 else 0 end) as total,
            sum(case when conversation_messages.created_at >= moderator_reads.read_at then 1 else 0 end) as unread
          })
      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]
      @message_count.default = OpenStruct.new(unread: 0, total: 0)
      @moderation = Hash[EntourageModeration.where(entourage_id: entourage_ids).pluck(:entourage_id, :moderated)]
      @moderation.default = false

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])

      render layout: 'admin_large'
    end

    def show
      @join_requests =
        @entourage
        .join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a
      @invitations =
        @entourage
        .entourage_invitations
        .where.not(status: :accepted)
        .includes(:invitee)
        .to_a
      @chat_messages  =
        @entourage
          .conversation_messages.ordered.includes(:user)
          .with_content
          .to_a

      @moderator_read  = @entourage.moderator_read_for(user: current_user)

      @messages_author = current_user

      reads = @entourage.join_requests.accepted
        .reject { |r| r.last_message_read.nil? || r.user_id == @messages_author.id }
        .reject { |r| r.last_message_read < @chat_messages.first.created_at if @chat_messages.any? }
        .sort_by(&:last_message_read)

      @last_reads = Hash.new { |h, k| h[k] = [] }
      (@chat_messages + [nil]).each_cons(2) do |message, next_message|
        while reads.any? &&
              reads.first.last_message_read >= message.created_at &&
              (!next_message ||
               reads.first.last_message_read < next_message.created_at) do
          @last_reads[message.full_object_id].push reads.shift
        end
      end

      @unread_content = @moderator_read.nil?

      render layout: 'admin_large'
    end

    def moderator_read
      read_at =
        if params[:read_at]
          DateTime.parse(params[:read_at])
        else
          Time.zone.now
        end

      ModeratorReadsService
        .new(entourage: @entourage, moderator: current_user)
        .mark_as_read(at: read_at)

      redirect_to [:admin, @entourage]
    end

    def moderator_unread
      ModeratorReadsService
        .new(entourage: @entourage, moderator: current_user)
        .mark_as_unread
      redirect_to [:admin, @entourage]
    end

    def edit
    end

    def update
      update_params = entourage_params.to_h.with_indifferent_access
      if metadata_starts_at.present?
        update_params[:metadata] ||= {}
        update_params[:metadata][:starts_at] =
          Date
            .strptime(metadata_starts_at[:date])
            .in_time_zone
            .change(
              hour: metadata_starts_at[:hour],
              min:  metadata_starts_at[:min]
            )
      end
      if EntourageServices::EntourageBuilder.update(entourage: @entourage, params: update_params)
        redirect_to [:edit, :admin, @entourage], notice: "Entourage mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    def message
      user = current_user

      join_request =
        user.join_requests.find_or_create_by!(joinable: @entourage) do |join_request|
          join_request.role = JoinRequestsServices::JoinRequestBuilder.default_role(@entourage)
          join_request.status = JoinRequest::ACCEPTED_STATUS
        end

      chat_builder = ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: user,
        joinable: @entourage,
        join_request: join_request
      )

      chat_builder.create do |on|
        on.success do |message|
          ModeratorReadsService
            .new(entourage: @entourage, moderator: current_user)
            .mark_as_read
          redirect_to [:admin, @entourage, anchor: "chat_message-#{message.id}"]
        end

        on.failure do |message|
          redirect_to [:admin, @entourage], alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    def destroy_message
      case params[:type]
      when 'ChatMessage'
        chat_message = ChatMessage.find(params[:id])
        chat_message.destroy
        entourage = chat_message.messageable
      when 'JoinRequest'
        join_request = JoinRequest.find(params[:id])
        join_request.message = nil
        join_request.save
        entourage = join_request.joinable
      end

      redirect_to [:admin, entourage]
    end

    def sensitive_words
      highlighted = SensitiveWordsService.highlight_entourage @entourage
      @title = highlighted[:title]
      @description = highlighted[:description]
      @matches = highlighted[:matches]

      render layout: 'admin_large'
    end

    def sensitive_words_check
      check = @entourage.sensitive_words_check || @entourage.build_sensitive_words_check
      check.status = params[:status]
      check.save!
      redirect_to [:admin, @entourage]
    end

    private
    def set_entourage
      @entourage = Entourage.find(params[:id])
    end

    def entourage_params
      metadata_keys = params.dig(:entourage, :metadata).try(:keys) || []
      metadata_keys -= [:starts_at]
      params.require(:entourage).permit(:status, :title, :description, :category, :entourage_type, :display_category, :latitude, :longitude, :public, metadata: metadata_keys)
    end

    def metadata_starts_at
      params.dig(:metadata, :starts_at)&.slice(:date, :hour, :min)
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end
  end
end
