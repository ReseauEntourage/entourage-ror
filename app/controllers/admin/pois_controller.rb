module Admin
  class PoisController < Admin::BaseController
    before_action :set_poi, only: [:edit, :update, :destroy]
    before_action :authenticate_super_admin!, only: [:import]

    def index
      @params = params.permit([q: [:name_or_adress_cont, :postal_code_start, :postal_code_in_hors_zone]]).to_h
      @q = Poi.ransack(@params[:q])
      @pois = @q.result(distinct: true)
                         .page(params[:page])
                         .per(25)
                         .order("created_at DESC")

      if @params[:q]
        @pois = @pois.in_postal_code(@params[:q][:postal_code_start]) if @params[:q][:postal_code_start]
        @pois = @pois.in_postal_code(:hors_zone) if @params[:q][:postal_code_in_hors_zone]
      end

      @pois
    end

    def new
      @poi = Poi.new
    end

    def edit
    end

    def update
      return redirect_to edit_admin_poi_path(params[:id]), flash: {
        error: "Vous ne pouvez pas mettre à jour un POI Soliguide"
      } if @poi.source_soliguide?

      @poi = PoiServices::PoiGeocoder.new(poi: @poi, params: poi_params).geocode
      if @poi.errors.blank? && @poi.update(poi_params)
        redirect_to admin_pois_path, notice: "Le POI a bien été mis à jour"
      else
        render :edit
      end
    end

    def destroy
      @poi.destroy
      redirect_to admin_pois_path
    end

    def create
      @poi = Poi.new(poi_params)
      @poi = PoiServices::PoiGeocoder.new(poi: @poi, params: poi_params).geocode

      if @poi.errors.blank? && @poi.save(poi_params)
        redirect_to admin_pois_url, notice: "Le POI a bien été créé"
      else
        render :new
      end
    end

    def import
      MemberMailer.poi_import(
        csv: CSV.read(params["poi"]["file"].path, headers: true).to_csv,
        recipient: current_user.email
      ).deliver_later

      redirect_to admin_pois_path, notice: "Un email sera envoyé après l'import pour indiquer le nombre de POI importés et les erreurs éventuelles"
    end

    private
    def poi_params
      params.require(:poi).permit(:name, :adress, :description, :audience, :email, :website, :phone, :category_id, :validated, :longitude, :latitude, :category_ids => [])
    end

    def set_poi
      @poi = Poi.find(params[:id])
    end
  end
end
