module Admin
  class EntouragesController < Admin::BaseController
    def index
      @entourages = Entourage.includes(:user => [ :organization ])
                             .page(params[:page])
                             .per(params[:per])
                             .order("created_at DESC")
    end

    def show
      @entourage     = Entourage.find params[:id]
      @members       = @entourage.members
      @join_requests = @entourage.join_requests.includes(:user)
      @invitations   = @entourage.entourage_invitations.includes(:invitee)
      @chat_messages = @entourage.chat_messages.includes(:user)
    end
  end
end
