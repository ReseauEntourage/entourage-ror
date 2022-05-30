module Api
  module V1
    class NeighborhoodsController < Api::V1::BaseController
      before_action :set_neighborhood, only: [:show, :update, :destroy, :report]
      allow_anonymous_access only: [:report]

      def index
        render json: NeighborhoodServices::Finder.search(current_user, params[:q]), root: :neighborhoods, each_serializer: ::V1::NeighborhoodSerializer
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

      def report
        if report_params[:category].blank?
          render json: {
            code: 'CANNOT_REPORT_NEIGHBORHOOD',
            message: 'category is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalNeighborhood.new(
          neighborhood: @neighborhood,
          reporting_user: current_user,
          category: report_params[:category],
          message: report_params[:message]
        ).notify

        head :created
      end

      private

      def set_neighborhood
        @neighborhood = Neighborhood.find(params[:id])
      end

      def neighborhood_params
        params.require(:neighborhood).permit(:name, :description, :welcome_message, :ethics, :latitude, :longitude, :neighborhood_image_id, :other_interest, interests: [])
      end

      def report_params
        params.require(:report).permit(:category, :message)
      end
    end
  end
end
