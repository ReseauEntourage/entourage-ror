module Admin
  class JoinRequestsController < Admin::BaseController
    before_action :ensure_moderator!, only: [:create, :destroy]

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

    def destroy
      @join_request = JoinRequest.find(params[:id])
      @joinable = @join_request.joinable

      if @join_request.update(status: :cancelled)
        flash[:success] = "La personne a bien été désinscrite."
      else
        flash[:error] = "La personne n'a pas pu être désinscrite : #{@join_request.errors.full_messages.to_sentence}"
      end

      redirect_to case @joinable
      when Neighborhood
        show_members_admin_neighborhood_path(@joinable)
      when Entourage
        show_members_admin_entourage_path(@joinable)
      else
        [:admin, @joinable]
      end
    end
  end
end
