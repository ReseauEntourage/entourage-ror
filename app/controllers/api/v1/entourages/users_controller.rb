module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        before_action :set_entourage
        before_action :set_join_request, only: [:update, :destroy]

        #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours/1017/users.json?token=07ee026192ea722e66feb2340a05e3a8"
        def index
          render json: @entourage.join_requests, root: "users", each_serializer: ::V1::JoinRequestSerializer
        end

        #curl -X POST -H "Content-Type: application/json" -d '{"request":{"message": "a join message"}}' "http://localhost:3000/api/v1/entourages/1017/users.json?token=azerty"
        def create
          join_request_builder = JoinRequestsServices::JoinRequestBuilder.new(joinable: @entourage, user: current_user, message: params.dig(:request, :message))
          join_request_builder.create do |on|
            on.success do |join_request|
              render json: join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer
            end

            on.failure do |join_request|
              render json: {message: 'Could not create entourage participation request', reasons: join_request.errors.full_messages}, status: :bad_request
            end
          end
        end

        #curl -X PUT -H "Content-Type: application/json" -d '{"request":{"message": "a join message"}}' "http://localhost:3000/api/v1/entourages/1017/users/123.json?token=azerty"
        #curl -X PUT -H "Content-Type: application/json" -d '{"user":{"status": "accepted"}}' "http://localhost:3000/api/v1/entourages/1017/users/123.json?token=azerty"
        def update
          status = params.dig(:user, :status)
          message = params.dig(:request, :message)
          updater = JoinRequestsServices::JoinRequestUpdater.new(join_request: @join_request,
                                                                 status: status,
                                                                 message: message,
                                                                 current_user: @current_user)

          updater.update do |on|
            on.invalid_status do |status|
              render json: {message: "Invalid status : #{status}"}, status: :bad_request
            end

            on.success do
              head :no_content
            end

            on.failure do |join_request|
              render json: {message: 'Could not update entourage participation request status', reasons: join_request.errors.full_messages}, status: :bad_request
            end

            on.not_authorised do
              return render json: {message: "You are not accepted in this entourage, you don't have rights to manage users of this entourage"}, status: :unauthorized
            end
          end
        end

        #curl -X DELETE -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/454/users/428.json?token=azerty"
        def destroy
          updater = JoinRequestsServices::JoinRequestUpdater.new(join_request: @join_request,
                                                                 status: status,
                                                                 message: nil,
                                                                 current_user: @current_user)

          updater.reject do |on|
            on.success do |join_request|
              render json: join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer
            end

            on.failure do |join_request|
              render json: {message: 'Could not update entourage participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
            end

            on.not_authorised do
              render json: {message: "You are not accepted in this entourage, you don't have rights to manage users of this entourage"}, status: :unauthorized
            end

            on.remove_author do
              render json: {message: 'Cannot remove the author of the entourage'}, status: :bad_request
            end

            on.quit do
              #JoinRequest was destroyed we return an empty join request
              render json: @join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer
            end
          end
        end

        private
        def set_entourage
          @entourage = Entourage.find(params[:entourage_id])
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @entourage, user: User.find(params[:id])).first!
        end
      end
    end
  end
end