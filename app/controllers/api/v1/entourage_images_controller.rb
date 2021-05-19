module Api
  module V1
    class EntourageImagesController < Api::V1::BaseController
      def index
        render json: EntourageImage.all, each_serializer: ::V1::EntourageImageSerializer
      end

      def show
        render json: EntourageImage.find(params[:id]), status: 200, serializer: ::V1::EntourageImageSerializer
      end
    end
  end
end
