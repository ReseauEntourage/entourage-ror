module Admin
  class SuperAdminController < Admin::BaseController
    PER_PAGE = 50

    layout 'admin_large'

    before_action :authenticate_super_admin!

    def soliguide
      @pois = []
      @poi = nil

      params[:latitude] ||= PoiServices::Soliguide::PARIS[:latitude]
      params[:longitude] ||= PoiServices::Soliguide::PARIS[:longitude]

      soliguide = PoiServices::Soliguide.new(soliguide_params)
      @pois = PoiServices::SoliguideIndex.post(soliguide.query_params)
    end

    def soliguide_show
      @poi = PoiServices::SoliguideShow.get(params[:id][1..], current_user.lang)
    end

    private

    def soliguide_params
      params.permit(:limit, :latitude, :longitude, :distance, :category_ids, :query)
    end
  end
end
