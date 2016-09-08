module Api
  module V1
    class ToursController < Api::V1::BaseController
      before_action :set_tour, only: [:show, :update]

      def index
        return render json: {message: 'Public users cannot list tours'}, status: 403 if current_user.public?
        @tours = TourServices::TourFilterApi.new(user: current_user,
                                                 status: params[:status],
                                                 type: params[:type],
                                                 vehicle_type: params[:vehicle_type],
                                                 latitude: params[:latitude],
                                                 longitude: params[:longitude],
                                                 distance: params[:distance],
                                                 page: params[:page],
                                                 per: per).tours
        render json: @tours, status: 200, each_serializer: ::V1::TourSerializer, scope: {user: current_user}
      end

      #curl -X POST -d '{"tour": { "tour_type":"medical", "vehicle_type":"feet", "distance": 8543.65 }}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours.json?token=azerty"
      def create
        tour_builder = TourServices::TourBuilder.new(params: tour_params, user: current_user)
        tour_builder.create do |on|
          on.success do |tour|
            render json: tour, status: 201, serializer: ::V1::TourSerializer, scope: {user: current_user}
          end

          on.failure do |tour|
            render json: {message: 'Could not create tour', reasons: tour.errors.full_messages}, status: 400
          end
        end
      end

      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours/1948.json?token=azerty"
      def show
        render json: @tour, status: 200, serializer: ::V1::TourSerializer, scope: {user: current_user}
      end

      #curl -X PUT -d '{ "status":"closed"}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours/1948.json?token=azerty"
      def update
        if @tour.user != @current_user
          head 403
        else
          if tour_params[:status]=="closed"
            TourServices::CloseTourService.new(tour: @tour, params: tour_params).close!
          end

          if tour_params[:status]=="freezed"
            TourServices::FreezeTourService.new(tour: @tour, user: @current_user).freeze!
          end

          @tour.length = tour_params[:distance]
          @tour.update(tour_params.except(:status, :distance, :start_time, :end_time))
          render json: @tour, status: 200, serializer: ::V1::TourSerializer, scope: {user: current_user}
        end
      end

      private

      def tour_params
        params.require(:tour).permit(:tour_type, :status, :vehicle_type, :distance, :start_time, :end_time)
      end

      def set_tour
        @tour = Tour.find(params[:id])
      end
    end
  end
end
