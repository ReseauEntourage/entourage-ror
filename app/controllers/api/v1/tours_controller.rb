module Api
  module V1
    class ToursController < Api::V1::BaseController
      before_action :set_tour, only: [:show, :update]

      def create
        tour_builder = TourServices::TourBuilder.new(params: tour_params, user: current_user)
        tour_builder.create do |on|
          on.create_success do |tour|
            render json: tour, status: 201, serializer: ::V1::TourSerializer
          end

          on.create_failure do |tour|
            render json: {message: 'Could not create tour', reasons: tour.errors.full_messages}, status: 400
          end
        end
      end

      def show
        render json: @tour, status: 200, serializer: ::V1::TourSerializer
      end

      def index
        @tours = Tour.includes(:tour_points).includes(:tours_users).includes(:user).where(nil)
        @tours = @tours.type(params[:type]) if params[:type].present?
        @tours = @tours.vehicle_type(Tour.vehicle_types[params[:vehicle_type]]) if params[:vehicle_type].present?
        @tours = @tours.where(status: params[:status]) if params[:status].present?

        if (params[:latitude].present? && params[:longitude].present?)
          center_point = [params[:latitude], params[:longitude]]
          distance = params.fetch(:distance, 10)
          box = Geocoder::Calculations.bounding_box(center_point, distance, :units => :km)
          points = TourPoint.within_bounding_box(box).select(:tour_id).distinct
          @tours = @tours.where(id: points)
        end

        @tours = @tours.where("updated_at > ?", 24.hours.ago).order(updated_at: :desc).limit(params.fetch(:limit, 10))
        @presenters = TourCollectionPresenter.new(tours: @tours)
        render json: @tours, status: 200, each_serializer: ::V1::TourSerializer, scope: current_user
      end

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
          @tour.update_attributes(tour_params.except(:status, :distance))
          render json: @tour, status: 200, serializer: ::V1::TourSerializer
        end
      end

      private

      def tour_params
        params.require(:tour).permit(:tour_type, :status, :vehicle_type, :distance)
      end

      def set_tour
        @tour = Tour.find(params[:id])
      end
    end
  end
end
