module Admin
  class PoisController < Admin::BaseController
    def index
      @pois = Poi.order("created_at DESC").page(params[:page]).per(25)
    end

    def new
      @poi = Poi.new
    end

    def create
      @poi = Poi.new(poi_params)
      @poi.geocode
      if @poi.save
        redirect_to admin_pois_url, notice: "Le POI a bien été créé"
      else
        render :new, alert: "le POI n'a pas pu être créé"
      end
    end

    private
    def poi_params
      params.require(:poi).permit(:name, :adress, :audience, :email, :category_id)
    end
  end
end