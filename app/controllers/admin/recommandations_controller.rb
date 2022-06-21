module Admin
  class RecommandationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_recommandation, only: [:edit, :update, :destroy, :edit_image, :update_image]

    def index
      @recommandations = Recommandation.unscoped.page(page).per(per)
    end

    def new
      @recommandation = Recommandation.new

      # pre-fill targeting
      @recommandation.areas = ModerationArea.all_slugs
      @recommandation.user_goals = UserGoalPresenter.all_slugs(community)
    end

    def create
      @recommandation = Recommandation.new(recommandation_params)

      if @recommandation.save
        redirect_to admin_recommandations_path, notice: "La recommandation a bien été créée"
      else
        render :new
      end
    end

    def edit
    end

    def update
      @recommandation.assign_attributes(recommandation_params)

      if @recommandation.save
        redirect_to edit_admin_recommandation_path(@recommandation), notice: "Recommandation mise à jour"
      else
        render :edit
      end
    end

    def edit_image
      @recommandation_images = RecommandationImage.all
    end

    def update_image
      @recommandation.assign_attributes(recommandation_params)

      if @recommandation.save
        redirect_to edit_admin_recommandation_path(@recommandation)
      else
        @recommandation_images = RecommandationImage.all
        render :edit_image
      end
    end

    def destroy
    end

    private

    def set_recommandation
      @recommandation = Recommandation.unscoped.find(params[:id])
    end

    def recommandation_params
      params.require(:recommandation).permit(
        :status,
        :name,
        :recommandation_image_id,
        :instance,
        :action,
        :url,
        areas: [],
        user_goals: []
      )
    end
  end
end
