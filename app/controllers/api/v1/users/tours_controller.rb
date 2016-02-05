module Api
  module V1
    module Users
      class ToursController < Api::V1::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min
          tours = @user.tours.order(updated_at: :desc).page(page).per(per)
          if position_params?
            tours_within_distance = TourPoint.select(:tour_id).around(params[:latitude], params[:longitude], params[:distance]).map(&:tour_id)
            tours = tours.where(id: tours_within_distance)
          end
          render json: tours, status: 200, each_serializer: ::V1::TourSerializer
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def position_params?
          params[:distance] &&
          params[:latitude] &&
          params[:longitude]
        end
      end
    end
  end
end

