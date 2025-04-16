module Api
  module V1
    module Smalltalks
      class UsersController < Api::V1::BaseController
        before_action :set_smalltalk, only: [:index, :destroy]
        before_action :set_join_request, only: [:destroy]
        before_action :authorised_user?, only: [:destroy]

        def index
          # smalltalk members
          render json: @smalltalk.join_requests
            .includes(user: :partner)
            .search_by_member(params[:query])
            .ordered_by_validated_users
            .accepted
            .page(page)
            .per(per), root: "users", each_serializer: ::V1::JoinRequestSerializer, scope: {
              user: current_user
            }
        end

        def destroy
          return render json: {
            message: 'Could not find smalltalk participation for user'
          }, status: :unauthorized unless @join_request

          if @join_request.update(status: :cancelled)
            render json: @join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not destroy smalltalk participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        private

        def set_smalltalk
          @smalltalk = Smalltalk.find(params[:smalltalk_id])
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @smalltalk, user: current_user).first
        end

        def authorised_user?
          return unless params[:id].present?

          unless current_user == User.find(params[:id])
            render json: { message: 'unauthorized' }, status: :unauthorized
          end
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per].try(:to_i) || 100
        end
      end
    end
  end
end
