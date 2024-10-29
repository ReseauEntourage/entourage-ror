module Admin
  class ModerationAreasController < Admin::BaseController
    before_action :authenticate_super_admin!, except: [:index, :show, :edit, :update]

    layout 'admin_large'

    def index
      @params = params.permit(:region)
      @default_slack_id = ModerationServices::DEFAULT_SLACK_MODERATOR_ID
      @default_moderator = User.find_by(slack_id: @default_slack_id, admin: true, validation_status: :validated)

      @moderation_areas = ModerationArea
        .includes(:animator, :sourcing, :community_builder)
        .in_region(@params[:region])
        .order(:departement)
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

    def show
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
        format.html { redirect_to admin_moderation_areas, notice: 'Com-anim mis à jour avec succès.' }
      end
    end

    def update_sourcing
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(sourcing_id: params[:sourcing_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/sourcing" }
        format.html { redirect_to admin_moderation_areas, notice: 'Sourcing mis à jour avec succès.' }
      end
    end

    def update_community_builder
      @moderation_area = ModerationArea.find(params[:id])
      @moderation_area.update(community_builder_id: params[:community_builder_id])
      respond_to do |format|
        format.js { render "admin/moderation_areas/update/community_builder" }
        format.html { redirect_to admin_moderation_areas, notice: 'Community builder mis à jour avec succès.' }
      end
    end

    private

    def area_params
      return super_admin_area_params if current_user.super_admin?

      area_params_for_moderator
    end

    def super_admin_area_params
      params.require(:moderation_area).permit(
        :animator_id,
        :sourcing_id,
        :community_builder_id,
        :departement,
        :name,
        :welcome_message_1_offer_help,
        :welcome_message_1_ask_for_help,
        :welcome_message_1_organization,
        :welcome_message_1_goal_not_known,
      )
    end

    def area_params_for_moderator
      params.require(:moderation_area).permit(
        :welcome_message_1_offer_help,
        :welcome_message_1_ask_for_help,
        :welcome_message_1_organization,
        :welcome_message_1_goal_not_known,
      )
    end
  end
end
