module Admin
  class NeighborhoodsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood, only: [:edit, :update]

    def index
      @params = params.permit([:area]).to_h
      @area = params[:area].presence&.to_sym || :all

      @neighborhoods = Neighborhood.includes([:user, :taggings])
      @neighborhoods = @neighborhoods.with_moderation_area(@area.to_s) if @area && @area != :all
      @neighborhoods = @neighborhoods.order(created_at: :desc).page(page).per(per)
    end

    def edit
    end

    def update
      @neighborhood.assign_attributes(neighborhood_params)

      if @neighborhood.save
        redirect_to edit_admin_neighborhood_path(@neighborhood)
      else
        render :edit
      end
    end

    private

    def set_neighborhood
      @neighborhood = Neighborhood.find(params[:id])
    end

    def neighborhood_params
      params.require(:neighborhood).permit(:name, :description, :interest_list, interests: [])
    end
  end
end
