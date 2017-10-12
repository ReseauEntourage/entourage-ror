module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update, :moderator_read, :moderator_unread]

    def index
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
        .includes(user: [ :organization ])
        .page(params[:page])
        .per(params[:per])
        .with_moderator_reads_for(user: current_user)
        .select("entourages.*, moderator_reads is null and entourages.created_at >= now() - interval '1 week' as unread")
        .group("entourages.id, moderator_reads.id")
        .joins(:conversation_messages)
        .with_moderator_reads_for(user: current_user)
        .order(%(
          case
          when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
          when max(conversation_messages.created_at) >= moderator_reads.read_at then 1
          else 2
          end
        ))
        .order("created_at DESC")
        .to_a

      @entourages = Kaminari.paginate_array(@entourages, total_count: @q.result.count).page(params[:page]).per(10)
      entourage_ids = @entourages.map(&:id)
      @member_count =
        JoinRequest
          .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :accepted)
          .joins(:user)
          .merge(User.where(admin: false))
          .group(:joinable_id)
          .count
      @invitation_count =
        EntourageInvitation
          .where(invitable_type: :Entourage, invitable_id: entourage_ids)
          .group(:invitable_id, :status)
          .count
      @invitation_count.default = 0
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

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])
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

      @unread_content = @moderator_read.nil?
    end

    def moderator_read
      moderator_read = @entourage.moderator_read_for(user: current_user)
      read_at =
        if params[:read_at]
          DateTime.parse(params[:read_at])
        else
           Time.zone.now
        end

      if moderator_read
        moderator_read.update_column(:read_at, read_at)
      else
        @entourage.moderator_reads.create!(user: current_user, read_at: read_at)
      end

      redirect_to [:admin, @entourage]
    end

    def moderator_unread
      @entourage.moderator_read_for(user: current_user).delete
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

    private
    def set_entourage
      @entourage = Entourage.find(params[:id])
    end

    def entourage_params
      params.require(:entourage).permit(:status, :title, :description, :category, :display_category, :latitude, :longitude)
    end
  end
end
