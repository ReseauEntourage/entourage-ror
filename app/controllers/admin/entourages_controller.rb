module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update]

    def index
      @q = Entourage.ransack(params[:q])
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
      @chat_message_count =
        ChatMessage
          .where(messageable_type: :Entourage, messageable_id: entourage_ids)
          .group(:messageable_id)
          .count
      @chat_message_count.default = 0
    end

    def show
      @members       = @entourage.members
      @join_requests = @entourage.join_requests.includes(:user)
      @invitations   = @entourage.entourage_invitations.includes(:invitee)
      @chat_messages = @entourage.chat_messages.includes(:user)
    end

    def edit
    end

    def update
      if @entourage.update(entourage_params)
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
      params.require(:entourage).permit(:status, :title, :description, :category)
    end
  end
end
