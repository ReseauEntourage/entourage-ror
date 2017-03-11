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
      params.require(:entourage).permit(:status, :title, :description)
    end
  end
end
