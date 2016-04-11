module Api
  module V1
    module Tours
      class UsersController < Api::V1::BaseController
        before_action :set_tour
        before_action :set_join_request, only: [:update, :destroy]
        before_action :check_current_user_member_of_tour, only: [:update, :destroy]

        def index
          render json: @tour.join_requests, root: "users", each_serializer: ::V1::JoinRequestSerializer
        end

        #curl -X POST -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours/1017/users.json?token=07ee026192ea722e66feb2340a05e3a8"
        def create
          join_request_builder = JoinRequestsServices::JoinRequestBuilder.new(joinable: @tour, user: current_user)
          join_request_builder.create do |on|
            on.create_success do |join_request|
              render json: join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer
            end

            on.create_failure do |join_request|
              render json: {message: 'Could not create tour participation request', reasons: join_request.errors.full_messages}, status: :bad_request
            end
          end
        end

        def update
          status = params[:user].try(:[], :status)
          return render json: {message: 'Missing status'}, status: :bad_request unless status

          return render json: {message: "Invalid status : #{status}"}, status: :bad_request unless status == "accepted"

          user_status = TourServices::JoinRequestStatus.new(join_request: @join_request)
          if user_status.accept!
            head :no_content
          else
            render json: {message: 'Could not update tour participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
          end
        end

        def destroy
          if @join_request.user == @tour.user
            return render json: {message: 'Cannot remove the author of the tour'}, status: :bad_request
          end

          user_status = TourServices::JoinRequestStatus.new(join_request: @join_request)
          if user_status.reject!
            render json: @join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer
          else
            render json: {message: 'Could not update tour participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
          end
        end

        private

        def check_current_user_member_of_tour
          current_join_request = JoinRequest.where(joinable: @tour, user: current_user).first

          unless current_join_request && TourServices::JoinRequestStatus.new(join_request: current_join_request).accepted?
            return render json: {message: "You are not accepted in this tour, you don't have rights to manage users of this tour"}, status: :unauthorized
          end
        end

        def set_tour
          @tour = Tour.find(params[:tour_id])
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @tour, user: User.find(params[:id])).first!
        end
      end
    end
  end
end