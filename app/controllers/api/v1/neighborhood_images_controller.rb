module Api
  module V1
    class NeighborhoodImagesController < Api::V1::BaseController
      def index
        render json: NeighborhoodImage.includes(:image_url_medium).order(id: :desc), each_serializer: ::V1::NeighborhoodImageSerializer
      end

      def show
        render json: NeighborhoodImage.find(params[:id]), status: 200, serializer: ::V1::NeighborhoodImageSerializer
      end
    end
  end
end
