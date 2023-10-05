module Admin
  class NeighborhoodMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood_message_broadcast, only: [:edit, :update, :clone, :kill, :broadcast, :update_neighborhoods]

    def index
      @params = params.permit([:status]).to_h
      @status = params[:status].presence&.to_sym || :draft

      @neighborhood_message_broadcasts = NeighborhoodMessageBroadcast.with_status(@status).order(created_at: :desc)
      @neighborhood_message_broadcasts = @neighborhood_message_broadcasts.page(page).per(per)
    end

    def new
      @neighborhood_message_broadcast = NeighborhoodMessageBroadcast.new
    end

    def create
      @neighborhood_message_broadcast = NeighborhoodMessageBroadcast.new(neighborhood_message_broadcast_params)
      if @neighborhood_message_broadcast.save
        redirect_to edit_admin_neighborhood_message_broadcast_path(@neighborhood_message_broadcast)
      else
        render :new
      end
    end

    def edit
      @tab = params[:tab].presence&.to_sym || :departements
    end

    def update
      @neighborhood_message_broadcast.assign_attributes(neighborhood_message_broadcast_params)

      if params.key?(:archive)
        @neighborhood_message_broadcast.status = :archived
      end

      if @neighborhood_message_broadcast.save
        redirect_to edit_admin_neighborhood_message_broadcast_path(@neighborhood_message_broadcast)
      else
        @neighborhood_message_broadcast.status = @neighborhood_message_broadcast.status_was
        render :edit
      end
    end

    def update_neighborhoods
      @neighborhood_message_broadcast.assign_attributes(neighborhood_message_broadcast_neighborhoods_param)

      if @neighborhood_message_broadcast.save!
        redirect_to edit_admin_neighborhood_message_broadcast_path(@neighborhood_message_broadcast), notice: "Votre modification a bien été prise en compte"
      else
        redirect_to edit_admin_neighborhood_message_broadcast_path(@neighborhood_message_broadcast), alert: "Votre modification n'a pas pu être prise en compte"
      end
    end

    def clone
      @neighborhood_message_broadcast = NeighborhoodMessageBroadcast.find(params[:id]).clone

      render :new
    end

    def kill
      @neighborhood_message_broadcast.update_attribute(:status, :sent)

      redirect_to admin_neighborhood_message_broadcasts_path(status: :sending)
    end

    def broadcast
      unless @neighborhood_message_broadcast.sent? || @neighborhood_message_broadcast.sending?
        @neighborhood_message_broadcast.update_attribute(:status, :sent)

        ConversationMessageBroadcastJob.perform_later(
          @neighborhood_message_broadcast.id,
          current_admin.id,
          @neighborhood_message_broadcast.content
        )
      end

      redirect_to edit_admin_neighborhood_message_broadcast_path(@neighborhood_message_broadcast)
    end

    private

    def neighborhood_message_broadcast_params
      params.require(:neighborhood_message_broadcast).permit(:content, :title, neighborhood_ids: [], departements: [])
    end

    def neighborhood_message_broadcast_neighborhoods_param
      params.require(:neighborhood_message_broadcast).permit(neighborhood_ids: [], departements: [])
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end

    def set_neighborhood_message_broadcast
      @neighborhood_message_broadcast = NeighborhoodMessageBroadcast.find(params[:id])
    end
  end
end
