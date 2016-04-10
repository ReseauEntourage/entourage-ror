module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        before_action :set_entourage
        before_action :set_join_request, only: [:update, :destroy]

        def index
          render json: @entourage.join_requests, root: "users", each_serializer: ::V1::JoinRequestSerializer
        end

        def destroy
          if @join_request.update(status: "rejected")
            head :no_content
          else
            render json: {message: 'Could not update entourage participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
          end
        end

        def update
          if @join_request.update(status: params[:user][:status])
            head :no_content
          else
            render json: {message: 'Could not update entourage participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
          end
        end

        def create
          join_request = JoinRequest.new(joinable: @entourage, user: current_user)

          if join_request.save
            render json: join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer
          else
            render json: {message: 'Could not create entourage participation request', reasons: join_request.errors.full_messages}, status: :bad_request
          end
        end

        private

        def set_entourage
          @entourage = Entourage.find(params[:entourage_id])
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @entourage, user: current_user).first!
        end
      end
    end
  end
end