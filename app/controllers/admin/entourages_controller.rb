module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update, :close, :renew, :cancellation, :cancel, :edit_image, :update_image, :moderator_read, :moderator_unread, :message, :show_members, :show_joins, :show_invitations, :show_messages, :show_comments, :show_siblings, :sensitive_words, :sensitive_words_check, :edit_type, :edit_owner, :update_owner, :admin_pin, :admin_unpin, :pin, :unpin]
    before_action :ensure_moderator!, only: [:message]

    before_action :set_default_index_params, only: [:index]
    before_action :set_index_params, only: [:index, :show, :edit, :show_messages, :show_invitations, :show_joins, :show_members]

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

      group_types = (params[:group_type] || 'action,outing').split(',')

      @q = Entourage.where(group_type: group_types).with_moderation
        .moderator_search(params[:moderator_id])
        .ransack(ransack_params)

      @entourages = @q.result.page(params[:page]).per(per_page)
        .with_moderator_reads_for(user: current_user)
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated,
          moderator_reads is null and entourages.created_at >= now() - interval '1 week' as unread
        ))
        .like(params[:search])
        .group("entourages.id, moderator_reads.id, entourage_moderations.id")
        .joins(%(join entourage_denorms on entourage_denorms.entourage_id = entourages.id))
        .order("case when status = 'open' then 1 else 2 end")
        .order(%(
          case
          when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
          when max(max_chat_message_created_at) >= moderator_reads.read_at then 1
          else 2
          end
        ))
        .order(%(
          admin_pin DESC,
          entourages.created_at DESC
        ))
        .to_a

      @entourages = Kaminari.paginate_array(@entourages, total_count: @q.result.count).page(params[:page]).per(per_page)

      entourage_ids = @entourages.map(&:id)

      @member_count = JoinRequest
          .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :accepted)
          .joins(:user)
          .merge(User.where(admin: false))
          .group(:joinable_id)
          .count
      @member_count.default = 0

      @requests_count = JoinRequest
        .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :pending)
        .group(:joinable_id)
        .pluck(%(
          joinable_id,
          count(*),
          count(case when updated_at <= now() - interval '48 hours' then 1 end)
        ))

      @requests_count = Hash[@requests_count.map { |id, total, late| [id, { total: total, late: late }]}]
      @requests_count.default = { total: 0, late: 0 }

      @reminded_users = Experimental::PendingRequestReminder.recent
        .where(user_id: @entourages.map(&:user_id))
        .pluck('distinct user_id')

      @reminded_users = Set.new(@reminded_users)

      @message_count = ConversationMessage
        .with_moderator_reads_for(user: current_user)
        .where(messageable_type: :Entourage, messageable_id: entourage_ids)
        .group(:messageable_id)
        .select(%{
          messageable_id,
          sum(case when conversation_messages.content <> '' then 1 else 0 end) as total,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at then 1 else 0 end) as unread,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at and conversation_messages.image_url is not null then 1 else 0 end) as unread_images
        })

      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]
      @message_count.default = OpenStruct.new(unread: 0, total: 0)
      @moderation = Hash[EntourageModeration.where(entourage_id: entourage_ids).pluck(:entourage_id, :moderated)]
      @moderation.default = false

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])
    end

    def new
      @entourage = Entourage.new(
        group_type: params[:group_type].to_sym,
        public: true
      )

      render :edit
    end

    def create
      entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
      entourage_builder.create do |on|
        on.success do |entourage|
          redirect_to edit_admin_entourage_path(entourage)
        end

        on.failure do |entourage|
          @entourage = entourage
          render :edit
        end
      end
    end

    def show
      @moderator_read = @entourage.moderator_read_for(user: current_user)
    end

    def show_members
      @moderator_read = @entourage.moderator_read_for(user: current_user)
      @requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a.find_all(&:is_accepted?)

      render :show
    end

    def show_joins
      @moderator_read = @entourage.moderator_read_for(user: current_user)

      @join_requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a
      @requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a.reject { |r|
          r.is_accepted? || (r.entourage_invitation_id && r.entourage_invitation_status != 'accepted')
        }

      render :show
    end

    def show_invitations
      @moderator_read = @entourage.moderator_read_for(user: current_user)
      @invitations = @entourage.entourage_invitations
        .where.not(status: :accepted)
        .includes(:invitee)
        .to_a

      render :show
    end

    def show_messages
      @moderator_read  = @entourage.moderator_read_for(user: current_user)

      @join_requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a

      @chat_messages = @entourage.parent_conversation_messages.ordered
          .includes(:user)
          .with_content
          .page(params[:page])
          .per(params[:per])

      reads = @entourage.join_requests.accepted
        .reject { |r| r.last_message_read.nil? || r.user_id == current_user.id }
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

      render :show
    end

    def show_comments
      @comments = ChatMessage.find(params[:message_id]).children.page(page).per(per)

      render :show
    end

    def show_siblings
      @siblings = Outing.find(params[:id]).siblings

      render :show
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

      redirect_to show_messages_admin_entourage_path(@entourage)
    end

    def moderator_unread
      ModeratorReadsService
        .new(entourage: @entourage, moderator: current_user)
        .mark_as_unread

      redirect_to show_messages_admin_entourage_path(@entourage)
    end

    def edit
    end

    def update
      update_params = entourage_params.to_h.with_indifferent_access

      if @entourage.group_type == 'outing' && params[:metadata].present?
        update_params[:metadata] ||= {}
        update_params[:metadata][:previous_at] = params[:metadata][:previous_at]
      end

      group_type_change = [
        @entourage.group_type&.to_sym,
        update_params[:group_type]&.to_sym
      ]
      group_type_change = nil if group_type_change.uniq.count == 1

      if group_type_change
        authorized_group_changes = [
          [:outing, :action],
          [:action, :outing],
          [:action, :group]
        ]
        raise unless group_type_change.in?(authorized_group_changes)

        @entourage.metadata = {}
      end

      if EntourageServices::EntourageBuilder.update(entourage: @entourage, params: update_params)
        Entourage.transaction do
          group_roles = {
            action: [:creator,   :member],
            outing: [:organizer, :participant],
            group:  [:admin,     :member]
          }
          role_changes = group_type_change.map { |type| group_roles[type] }.reduce(&:zip)
          role_changes.each do |old_role, new_role|
            @entourage.join_requests.where(role: old_role).update_all(role: new_role)
          end
        end if group_type_change

        redirect_to [:edit, :admin, @entourage], notice: "Entourage mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    def close
      if EntourageServices::EntourageBuilder.close(entourage: @entourage)
        redirect_to [:admin, @entourage], notice: "L'événement a été clôturé"
      else
        redirect_to [:admin, @entourage], alert: "L'événement n'a pas pu être clôturé : #{@entourage.errors.full_messages.to_sentence}"
      end
    end

    def renew
    end

    def cancellation
      redirect_to [:edit, :admin, @entourage], alert: "Seuls les événements peuvent être annulés" unless @entourage.outing?
    end

    def cancel
      if EntourageServices::EntourageBuilder.cancel(entourage: @entourage, params: cancel_params.to_h)
        redirect_to [:admin, @entourage], notice: "L'événement a été annulé"
      else
        redirect_to [:cancellation, :admin, @entourage], alert: "L'événement n'a pas pu être annulé : #{@entourage.errors.full_messages.to_sentence}"
      end
    end

    def duplicate_outing
      original = Outing.find(params[:id])
      @outing = original.dup

      if @outing.save
        redirect_to [:admin, @outing], notice: "L'événement a été dupliqué"
      else
        redirect_to [:admin, @original], alert: "L'événement n'a pas été dupliqué: #{@outing.errors.full_messages.to_sentence}"
      end
    end

    def edit_image
      redirect_to edit_admin_entourage_path(@entourage) and return unless @entourage.outing?

      @entourage_images = EntourageImage.all
    end

    def update_image
      redirect_to edit_admin_entourage_path(@entourage) and return unless @entourage.outing?

      @entourage.assign_attributes(entourage_params)

      if @entourage.save
        redirect_to edit_admin_entourage_path(@entourage)
      else
        @entourage_images = EntourageImage.all
        render :edit_image
      end
    end

    def admin_pin
      @entourage.update_column(:admin_pin, true)
      redirect_to [:admin, @entourage]
    end

    def admin_unpin
      @entourage.update_column(:admin_pin, false)
      redirect_to [:admin, @entourage]
    end

    def pin
      @entourage.update_column(:pin, true)
      redirect_to [:admin, @entourage]
    end

    def unpin
      @entourage.update_column(:pin, false)
      redirect_to [:admin, @entourage]
    end

    def edit_type
      new_type = params[:to]&.to_sym
      current_type = @entourage.group_type.to_sym
      case [current_type, new_type]
      when [:action, :outing]
        @entourage.group_type = :outing
        @entourage.entourage_type = :contribution
        @entourage.display_category = :event
        @entourage.public = nil
        @entourage.metadata = {}
        @entourage.online = false
      when [:outing, :action]
        @entourage.group_type = :action
        @entourage.entourage_type = nil
        @entourage.display_category = nil
        @entourage.public = nil
        @entourage.metadata = {}
        @entourage.online = false
      else
        raise "Changing #{current_type} to #{new_type} is not allowed"
      end
    end

    def edit_owner
    end

    def update_owner
      user_id = entourage_params[:user_id]
      message = entourage_params[:change_ownership_message]

      EntourageServices::ChangeOwner.new(@entourage).to(user_id, message) do |success, error_message|
        if success
          redirect_to [:admin, @entourage], notice: "Mise à jour réussie"
        else
          redirect_to [:edit_owner, :admin, @entourage], alert: error_message
        end
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
    end

    def sensitive_words_check
      check = @entourage.sensitive_words_check || @entourage.build_sensitive_words_check
      check.status = params[:status]
      check.save!
      redirect_to [:admin, @entourage]
    end

    private

    def per
      params[:per] || 25
    end

    def page
      params[:page] || 1
    end

    def set_entourage
      @entourage = Entourage.find(params[:id])
    end

    def set_index_params
      @params = index_params
    end

    def set_default_index_params
      # set default moderator_id
      main_moderator = ModerationServices.moderator_if_exists(community: :entourage)

      if current_user != main_moderator && (params.keys - ['controller', 'action']).none? && current_user.roles.include?(:moderator)
        params[:moderator_id] = current_user.id
      end

      params[:moderator_id] = 'any' unless params[:moderator_id].present?

      # set default status_in
      return if params[:q] && params[:q][:status_in].present?

      params[:q] ||= {}
      params[:q][:status_in] = ['open', 'suspended', 'full']
    end

    def index_params
      params.permit([:search, :moderator_id, q: [:entourage_type_eq, :status_in, :display_category_eq, :country_eq, :postal_code_start, :pin_eq, :group_type_eq, :moderation_action_outcome_blank, :created_at_lt, postal_code_start_any: [], postal_code_not_start_all: []]]).to_h
    end

    def entourage_params
      metadata_keys = params.dig(:entourage, :metadata).try(:keys) || [] # security issue
      metadata_keys -= [:starts_at]
      permitted = params.require(:entourage).permit(:group_type, :status, :title, :description, :category, :entourage_type, :display_category, :latitude, :longitude, :public, :online, :url, :event_url, :user_id, :entourage_image_id, :change_ownership_message, pins: [], metadata: metadata_keys)

      [:starts_at, :ends_at].each do |timestamp|
        datetime = params.dig(:entourage, :metadata, timestamp)&.slice(:date, :hour, :min)
        if datetime.present?
          permitted[:metadata] ||= {}
          permitted[:metadata][timestamp] = Date.strptime(datetime[:date]).in_time_zone.change(
            hour: datetime[:hour],
            min:  datetime[:min]
          )
        end
      end

      permitted
    end

    def cancel_params
      params.require(:entourage).permit(:cancellation_message)
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end
  end
end
