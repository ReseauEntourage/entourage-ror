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
        @neighborhood.user = current_user

        if @neighborhood.save
          render json: @neighborhood, status: 201, serializer: ::V1::NeighborhoodSerializer
        else
          render json: { message: "Could not create Neighborhood", reasons: @neighborhood.errors.full_messages }, status: 400
        end
      end

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized if @neighborhood.user != current_user

        @neighborhood.assign_attributes(neighborhood_params)

        if @neighborhood.save
          render json: @neighborhood, status: 200, serializer: ::V1::NeighborhoodSerializer
        else
          render json: {
            message: 'Could not update neighborhood', reasons: @neighborhood.errors.full_messages
          }, status: 400
        end
      end

      private

      def set_neighborhood
        @neighborhood = Neighborhood.find(params[:id])
      end

      def neighborhood_params
        params.require(:neighborhood).permit(:name, :description, :welcome_message, :ethics, :latitude, :longitude, :neighborhood_image_id, interests: [])
      end
    end
  end
end
