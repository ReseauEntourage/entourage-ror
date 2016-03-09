module Api
  module V1
    module Tours
      class UsersController < Api::V1::BaseController
        before_action :set_tour
        before_action :set_tour_user, only: [:update, :destroy]
        before_action :check_current_user_member_of_tour, only: [:update, :destroy]

        def index
          render json: @tour.tours_users, root: "users", each_serializer: ::V1::ToursUserSerializer
        end

        def create
          tour_user = ToursUser.new(tour: @tour, user: current_user)

          if tour_user.save
            render json: tour_user, root: "user", status: 201, serializer: ::V1::ToursUserSerializer
          else
            render json: {message: 'Could not create tour participation request', reasons: tour_user.errors.full_messages}, status: :bad_request
          end
        end

        def update
          status = params[:user].try(:[], :status)
          return render json: {message: 'Missing status'}, status: :bad_request unless status

          return render json: {message: "Invalid status : #{status}"}, status: :bad_request unless status == "accepted"

          user_status = TourServices::ToursUserStatus.new(tours_user: @tour_user)
          if user_status.accept!
            head :no_content
          else
            render json: {message: 'Could not update tour participation request status', reasons: @tour_user.errors.full_messages}, status: :bad_request
          end
        end

        def destroy
          if @tour_user.user == @tour.user
            return render json: {message: 'Cannot remove the author of the tour'}, status: :bad_request
          end

          user_status = TourServices::ToursUserStatus.new(tours_user: @tour_user)
          if user_status.reject!
            head :no_content
          else
            render json: {message: 'Could not update tour participation request status', reasons: @tour_user.errors.full_messages}, status: :bad_request
          end
        end

        private

        def check_current_user_member_of_tour
          current_tour_user = ToursUser.where(tour: @tour, user: current_user).first

          unless current_tour_user && TourServices::ToursUserStatus.new(tours_user: current_tour_user).accepted?
            return render json: {message: "You are not accepted in this tour, you don't have rights to manage users of this tour"}, status: :unauthorized
          end
        end

        def set_tour
          @tour = Tour.find(params[:tour_id])
        end

        def set_tour_user
          @tour_user = ToursUser.where(tour: @tour, user: User.find(params[:id])).first!
        end
      end
    end
  end
end