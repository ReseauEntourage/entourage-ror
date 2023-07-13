module Admin
  class ModerationAreasController < Admin::BaseController
    layout 'admin_large'

    def index
      @areas = ModerationArea.includes(:moderator).order(:id)
    end

    def new
      @area = ModerationArea.new
    end

    def create
      @area = ModerationArea.new(area_params)

      if @area.save
        redirect_to admin_moderation_areas_path, notice: "La zone de modération a bien été créée"
      else
        render :new
      end
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
        :moderator_id,
        :slack_moderator_id,
        :departement,
        :name,
        :welcome_message_1_offer_help,
        :welcome_message_1_ask_for_help,
        :welcome_message_1_organization,
        :welcome_message_1_goal_not_known,
      )
    end
  end
end
