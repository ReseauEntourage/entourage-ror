module Admin
  class ModerationAreasController < Admin::BaseController
    layout 'admin_large'

    def index
      @areas = ModerationArea.order(:id).all
    end

    def edit
      @area = ModerationArea.find(params[:id])
    end

    def update
      @area = ModerationArea.find(params[:id])

      @area.assign_attributes(area_params)

      if @area.save
        redirect_to edit_admin_moderation_area_path(@area), notice: "Zone mise à jour"
      else
        render :edit
      end
    end

    private

    def area_params
      params.require(:moderation_area).permit(
        :moderator_id, :welcome_message_1, :welcome_message_2,
        :welcome_message_1_offer_help,   :welcome_message_2_offer_help,
        :welcome_message_1_ask_for_help, :welcome_message_2_ask_for_help,
        :welcome_message_1_organization, :welcome_message_2_organization,
      )
    end
  end
end
