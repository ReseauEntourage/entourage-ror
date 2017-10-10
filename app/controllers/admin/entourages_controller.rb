module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update, :moderator_read]

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
      @entourages = @q.result(distinct: true)
                      .includes(user: [ :organization ])
                      .page(params[:page])
                      .per(params[:per])
                      .order("created_at DESC")

      entourage_ids = @entourages.map(&:id)
      @member_count =
        JoinRequest
          .where(joinable_type: :Entourage, joinable_id: entourage_ids)
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
            count(*) as total,
            sum(
              case when moderator_reads is null
                     or conversation_messages.created_at >= moderator_reads.read_at then
                1
              else
                0
              end
            ) as unread
          })
      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])
    end

    def show
      @members        = @entourage.members
      @join_requests  = @entourage.join_requests.includes(:user)
      @invitations    = @entourage.entourage_invitations.includes(:invitee)
      @chat_messages  = @entourage.conversation_messages.ordered.includes(:user)
      moderator_read  = @entourage.moderator_read_for(user: current_user)

      @first_unread = nil
      @unread_count = 0
      @chat_messages.each do |m|
        if @first_unread.nil? &&
           (moderator_read.nil? || m.created_at >= moderator_read.read_at)
          @first_unread = m
        end

        @unread_count += 1 if @first_unread
      end
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

    def edit
    end

    def update
      if EntourageServices::EntourageBuilder.update(entourage: @entourage, params: entourage_params)
        render :edit, notice: "Entourage mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    private
    def set_entourage
      @entourage = Entourage.find(params[:id])
    end

    def entourage_params
      params.require(:entourage).permit(:status, :title, :description, :category, :display_category)
    end
  end
end
