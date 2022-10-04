module Admin
  class RecommandationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_recommandation, only: [:edit, :update, :destroy, :edit_image, :update_image]

    def index
      @profile = params[:profile]&.to_sym || :offer_help
      @fragment = params[:fragment]&.to_i || 0
      @status = :active

      order = @profile == :offer_help ? :position_offer_help : :position_ask_for_help

      @recommandations = Recommandation.unscoped
        .for_profile(@profile)
        .fragment(@fragment)
        .order(order)
        .page(page)
        .per(per)
    end

    def new
      @recommandation = Recommandation.new

      # pre-fill targeting
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

    def reorder
      return redirect_to admin_recommandations_path unless Recommandation::FRAGMENTS.include?(params[:fragment].to_i)
      return redirect_to admin_recommandations_path unless [:offer_help, :ask_for_help].include?(params[:profile].to_sym)

      ordered_ids = (params[:ordered_ids] || "").to_s.split(',').map(&:to_i).uniq.reject(&:zero?)

      ApplicationRecord.transaction do
        Recommandation
          .active.where(id: ordered_ids)
          .sort_by { |r| ordered_ids.index(r.id) }
          .each.with_index(1) { |r, i| r.update_column("position_#{params[:profile]}", i) }
      end

      redirect_to admin_recommandations_path(fragment: params[:fragment], profile: params[:profile])
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
        :argument_type,
        :argument_value,
        user_goals: []
      )
    end
  end
end
