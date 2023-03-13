module Admin
  class JoinRequestsController < Admin::BaseController
    before_action :ensure_moderator!, only: [:create]

    def create
      @entourage = Entourage.find params[:joinable_id]

      builder = JoinRequestsServices::AdminAcceptedJoinRequestBuilder.new(joinable: @entourage, user: current_user)
      if builder.create
        flash[:success] = "Vous avez bien rejoint l'entourage."
        redirect_to admin_entourage_path(@entourage)
      else
        flash[:notice] = "Vous n'avez pas pu rejoindre l'entourage."
        redirect_to admin_entourage_path(@entourage)
      end
    end
  end
end
