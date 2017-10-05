module Admin
  class EntouragesController < Admin::BaseController
    before_action :set_entourage, only: [:show, :edit, :update]

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
      @chat_message_count =
        ChatMessage
          .where(messageable_type: :Entourage, messageable_id: entourage_ids)
          .group(:messageable_id)
          .count
      @chat_message_count.default = 0

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])
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
