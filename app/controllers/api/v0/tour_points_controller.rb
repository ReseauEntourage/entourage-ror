module Api
  module V0
    class TourPointsController < Api::V0::BaseController

      def create
        if @tour = Tour.find_by(id:params[:tour_id])
          @tour_points = @tour.tour_points.create(tour_point_params['tour_points'])

          if @tour_points.all?(&:valid?)
            @presenter = TourPresenter.new(tour: @tour)
            render "/api/v0/tours/show", status: 201
          else
            render "api/v0/tours/400", status: 400
          end
        else
          @id = params[:tour_id]
          render "api/v0/tours/404", status: 404
        end
      end

      def tour_point_params
        params.require(:tour_points)
        params.permit(tour_points: [:latitude, :longitude, :passing_time])
      end

    end
  end
end