module Api
  module V1
    class TourPointsController < Api::V1::BaseController
      def create
        tour = Tour.find(params[:tour_id])
        tour_points_builder = TourPointsServices::TourPointsBuilder.new(tour, params['tour_points'], :fail_with_exception)
        if tour_points_builder.create
          tp = params['tour_points'][0]
          tour.update(longitude: tp['longitude'], latitude: tp['latitude']) if [tour.longitude, tour.latitude].compact.blank?
          render json: {status: :ok}, status: 201
        else
          render json: {message: 'Could not create tour points'}, status: 400
        end
      end
    end
  end
end
