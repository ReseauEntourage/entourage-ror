module Admin
  class PoisController < Admin::BaseController
    before_action :set_poi, only: [:edit, :update, :destroy]

    def index
      @pois = Poi.unscoped.order("created_at DESC").page(params[:page]).per(25)
    end

    def new
      @poi = Poi.new
    end

    def edit
    end

    def update
      @poi = PoiServices::PoiGeocoder.new(poi: @poi, params: poi_params).geocode
      if @poi.errors.blank? && @poi.update(poi_params)
        redirect_to admin_pois_path, notice: "Le POI a bien été mis à jour"
      else
        @should_edit_gps = true
        render :edit
      end
    end

    def destroy
      @poi.destroy
      redirect_to admin_pois_path
    end

    def create
      @poi = Poi.new(poi_params)

      if @poi.save
        redirect_to admin_pois_url, notice: "Le POI a bien été créé"
      else
        render :new, alert: "le POI n'a pas pu être créé"
      end
    end

    private
    def poi_params
      params.require(:poi).permit(:name, :adress, :description, :audience, :email, :website, :phone, :category_id, :validated, :longitude, :latitude)
    end

    def set_poi
      @poi = Poi.unscoped.find(params[:id])
    end
  end
end