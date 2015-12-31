module Api
  module V0
    class MapController < Api::V0::BaseController

      def index
        pois_limit = params[:limit].nil? ? 45 : params[:limit]
        @categories = Category.all
        if(params.has_key?(:longitude) && params.has_key?(:latitude) && params.has_key?(:distance))
          @pois = Poi.around(params[:latitude], params[:longitude], params[:distance]).limit(pois_limit)
        else
          @pois = Poi.all.order(:id).limit(pois_limit)
        end

        categorie_json = JSON.parse(ActiveModel::ArraySerializer.new(@categories, each_serializer: CategorySerializer).to_json)
        poi_json = JSON.parse(ActiveModel::ArraySerializer.new(@pois, each_serializer: PoiSerializer).to_json)
        render json: {pois: poi_json, categories: categorie_json }, status: 200
      end
    end
  end
end
