module Api
  module V1
    module Tours
      class UsersController < Api::V1::BaseController
        before_action :set_tour
        before_action :set_tour_user, only: [:update, :destroy]

        def index
          render json: @tour.tours_users, root: "users", each_serializer: ::V1::ToursUserSerializer
        end

        def destroy
          if @tour_user.update(status: "rejected")
            head :no_content
          else
            render json: {message: 'Could not update tour participation request status', reasons: @tour_user.errors.full_messages}, status: :bad_request
          end
        end

        def update
          if @tour_user.update(status: params[:user][:status])
            head :no_content
          else
            render json: {message: 'Could not update tour participation request status', reasons: @tour_user.errors.full_messages}, status: :bad_request
          end
        end

        def create
          tour_user = ToursUser.new(tour: @tour, user: current_user)

          if tour_user.save
            render json: tour_user, root: "user", status: 201, serializer: ::V1::ToursUserSerializer
          else
            render json: {message: 'Could not create tour participation request', reasons: tour_user.errors.full_messages}, status: :bad_request
          end
        end

        private

        def set_tour
          @tour = Tour.find(params[:tour_id])
        end

        def set_tour_user
          @tour_user = ToursUser.where(tour: @tour, user: current_user).first!
        end
      end
    end
  end
end