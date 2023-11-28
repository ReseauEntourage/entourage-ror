module Admin
  class ModerationAreasController < Admin::BaseController
    layout 'admin_large'

    def index
      @moderation_areas = ModerationArea.order(:id)
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

    def update_animator
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(animator_id: params[:animator_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/animator" }
        format.html { redirect_to areas_path, notice: 'Animateur mis à jour avec succès.' }
      end
    end

    def update_mobilisator
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(mobilisator_id: params[:mobilisator_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/mobilisator" }
        format.html { redirect_to areas_path, notice: 'Mobilisateur mis à jour avec succès.' }
      end
    end

    def update_sourcing
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(sourcing_id: params[:sourcing_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/sourcing" }
        format.html { redirect_to areas_path, notice: 'Mobilisateur mis à jour avec succès.' }
      end
    end

    def update_accompanyist
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(accompanyist_id: params[:accompanyist_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/accompanyist" }
        format.html { redirect_to areas_path, notice: 'Mobilisateur mis à jour avec succès.' }
      end
    end

    private

    def area_params
      params.require(:moderation_area).permit(
        :moderator_id,
        :animator_id,
        :mobilisator_id,
        :sourcing_id,
        :accompanyist_id,
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
