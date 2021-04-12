module Api
  module V1
    class TourAreasController < Api::V1::BaseController
      def index
        render json: TourArea.all, each_serializer: ::V1::TourAreaSerializer
      end

      def show
        render json: TourArea.find(params[:id]), status: 200, serializer: ::V1::TourAreaSerializer
      end
    end
  end
end
