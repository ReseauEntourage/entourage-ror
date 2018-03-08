module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update, :moderator_read, :moderator_unread, :message, :sensitive_words, :sensitive_words_check]

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

      @q = Entourage.ransack(ransack_params)
      @entourages =
        @q.result
        .page(params[:page])
        .per(per_page)
        .with_moderator_reads_for(user: current_user)
        .with_moderation
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated,
          moderator_reads is null and entourages.created_at >= now() - interval '1 week' as unread
        ))
        .group("entourages.id, moderator_reads.id, entourage_moderations.id")
        .joins(:conversation_messages)
        .order(%(
          case
          when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
          when max(conversation_messages.created_at) >= moderator_reads.read_at then 1
          else 2
          end
        ))
        .order("created_at DESC")
        .includes(:sensitive_words_check)
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

      @messages_author = User.find_by email: 'guillaume@entourage.social'

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
      if EntourageServices::EntourageBuilder.update(entourage: @entourage, params: entourage_params)
        redirect_to [:edit, :admin, @entourage], notice: "Entourage mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    def message
      user = User.find_by email: 'guillaume@entourage.social'

      join_request =
        user.join_requests.find_or_create_by!(joinable: @entourage) do |join_request|
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
      params.require(:entourage).permit(:status, :title, :description, :category, :entourage_type, :display_category, :latitude, :longitude)
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end
  end
end
