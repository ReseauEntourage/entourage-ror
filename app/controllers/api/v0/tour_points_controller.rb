module Api
  module V0
    class TourPointsController < Api::V0::BaseController
      def create
        tour = Tour.find(params[:tour_id])
        tour_points = tour.tour_points.create(tour_point_params['tour_points'])
        if tour_points.all?(&:valid?)
          render json: tour_points, status: 201
        else
          render json: {message: 'Could not create tour points'}, status: 400
        end
      end

      def tour_point_params
        params.require(:tour_points)
        params.permit(tour_points: [:latitude, :longitude, :passing_time])
      end
    end
  end
end