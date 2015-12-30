module Api
  module V0
    class TourPointsController < Api::V0::BaseController
      def create
        tour = Tour.find(params[:tour_id])
        tour_point = tour.tour_points.new(tour_point_params['tour_points'])
        if tour_point.save
          render json: tour_point, status: 201
        else
          render json: {message: 'Could not create tour point', reasons: tour_point.errors.full_messages}, status: 400
        end
      end

      def tour_point_params
        params.require(:tour_points)
        params.permit(tour_points: [:latitude, :longitude, :passing_time])
      end
    end
  end
end