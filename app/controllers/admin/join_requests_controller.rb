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

    def accept
      @join_request = JoinRequest.find(params[:id])
      @join_request.update_attribute(:status, :accepted)

      redirect_to show_joins_admin_entourage_path(@join_request.joinable), notice: "La demande de l'utilisateur a été acceptée"
    rescue => e
      redirect_to show_joins_admin_entourage_path(@join_request.joinable), error: "La demande de l'utilisateur n'a pas pu être acceptée : #{e.message}"
    end
  end
end
