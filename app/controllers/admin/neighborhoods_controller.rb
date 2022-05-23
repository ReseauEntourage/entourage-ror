module Admin
  class NeighborhoodsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood, only: [:edit, :update]

    def index
      @neighborhoods = Neighborhood.includes([:user, :taggings]).page(page).per(per)
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
