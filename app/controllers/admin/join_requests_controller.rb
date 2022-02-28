module Admin
  class JoinRequestsController < Admin::BaseController
    before_action :ensure_moderator!

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
    end
  end
end
