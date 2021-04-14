module Admin
  class TourAreasController < Admin::BaseController
    layout 'admin_large'

    def index
      @tour_areas = TourArea.order(:id).all
    end

    def new
      @tour_area = TourArea.new
    end

    def create
      @tour_area = TourArea.new(tour_area_params)
      if @tour_area.save
        redirect_to admin_tour_areas_path, notice: "La zone a bien été créée"
      else
        render :new
      end
    end

    def edit
      @tour_area = TourArea.find(params[:id])
    end

    def update
      @tour_area = TourArea.find(params[:id])

      @tour_area.assign_attributes(tour_area_params)

      if @tour_area.save
        redirect_to edit_admin_tour_area_path(@tour_area), notice: "Zone mise à jour"
      else
        render :edit
      end
    end

    def destroy
      @tour_area = TourArea.find(params[:id])

      if @tour_area.destroy
        redirect_to admin_tour_areas_path, flash: {
          success: "Zone de maraude #{@tour_area.area} supprimée"
        }
      else
        redirect_to edit_admin_tour_area_path(@tour_area), flash: {
          notice: "La zone de maraude #{@tour_area.area} n'a pas pu être supprimée supprimée"
        }
      end
    end

    private

    def tour_area_params
      params.require(:tour_area).permit(
        :departement,
        :area,
        :status,
        :email
      )
    end
  end
end
