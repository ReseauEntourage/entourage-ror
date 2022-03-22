module Api
  module V1
    class NeighborhoodsController < Api::V1::BaseController
      before_action :set_neighborhood, only: [:show, :update, :destroy]

      def index
        # @caution Neighborhood.all to be replaced with a searched query
        render json: Neighborhood.all, root: :neighborhoods, each_serializer: ::V1::NeighborhoodSerializer
      end

      def show
        render json: @neighborhood, serializer: ::V1::NeighborhoodSerializer
      end

      def create
        @neighborhood = Neighborhood.new(neighborhood_params)

        if @neighborhood.save
          render json: @neighborhood, status: 201, serializer: ::V1::NeighborhoodSerializer
        else
          render json: { message: "Could not create Neighborhood", reasons: @neighborhood.errors.full_message }, status: 400
        end
      end

      private

      def set_neighborhood
        @neighborhood = Neighborhood.find(params[:id])
      end

      def neighborhood_params
        params.require(:neighborhood).permit(:name, :ethics, :latitude, :longitude, :interests, :photo_url)
      end
    end
  end
end
