module Api
  module V1
    module Outings
      class UsersController < Api::V1::BaseController
        before_action :set_outing, only: [:index, :create, :destroy]
        before_action :set_join_request, only: [:create, :destroy]
        before_action :authorised_user?, only: [:destroy]

        def index
          # outing members
          render json: @outing.join_requests.accepted, root: "users", each_serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
        end

        def create
          # join a outing
          return render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: {
            user: current_user
          } if @join_request.present? && @join_request.accepted?

          if @join_request.present?
            @join_request.status = :accepted
          else
            @join_request = JoinRequest.new(joinable: @outing, user: current_user, distance: params[:distance], role: :participant, status: :accepted)
          end

          if @join_request.save
            render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not create outing participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        def destroy
          return render json: {
            message: 'Could not find outing participation for user'
          }, status: :unauthorized unless @join_request

          if @join_request.update(status: :cancelled)
            render json: @join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not destroy outing participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        private

        def set_outing
          @outing = Outing.find(params[:outing_id])
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @outing, user: current_user).first
        end

        def authorised_user?
          return unless params[:id].present?

          unless current_user == User.find(params[:id])
            render json: { message: 'unauthorized' }, status: :unauthorized
          end
        end
      end
    end
  end
end
