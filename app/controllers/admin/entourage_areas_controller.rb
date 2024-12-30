module Admin
  class EntourageAreasController < Admin::BaseController
    before_action :authenticate_super_admin!

    before_action :set_entourage_area, only: [:edit, :update, :destroy]

    layout 'admin_large'

    def index
      @entourage_areas = EntourageArea.order(:postal_code).page(page).per(per)
    end

    def edit
    end

    def update
      @entourage_area.assign_attributes(entourage_area_params)

      if @entourage_area.save
        redirect_to edit_admin_entourage_area_path(@entourage_area)
      else
        render :edit
      end
    end

    def destroy
      if @entourage_area.destroy
        redirect_to admin_entourage_areas_path, notice: "La zone #{@entourage_area.display_name} a bien été supprimée"
      else
        redirect_to edit_admin_entourage_area_path(@entourage_area), error: "La zone #{@entourage_area.display_name} n'a pas pu être supprimée"
      end
    end

    private

    def set_entourage_area
      @entourage_area = EntourageArea.find(params[:id])
    end

    def entourage_area_params
      params.require(:entourage_area).permit(:postal_code, :antenne, :geo_zone, :display_name, :city)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
