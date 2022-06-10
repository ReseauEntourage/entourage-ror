module Api
  module V1
    module Resources
      class UsersController < Api::V1::BaseController
        before_action :set_resource
        before_action :set_user_resource, only: [:create, :destroy]

        def create
          return render json: @user_resource, status: 201, serializer: ::V1::UsersResourceSerializer if @user_resource.present? && @user_resource.watched?

          if @user_resource.present?
            @user_resource.watched = true
          else
            @user_resource = UsersResource.new(resource: @resource, user: current_user, watched: true)
          end

          if @user_resource.save
            render json: @user_resource, status: 201, serializer: ::V1::UsersResourceSerializer
          else
            render json: {
              message: 'Could not create resource watched request', reasons: @user_resource.errors.full_messages
            }, status: :bad_request
          end
        end

        def destroy
          render json: :ok, status: 200 unless @user_resource.present?
          render json: :ok, status: 200 unless @user_resource.watched?

          @user_resource.watched = false

          if @user_resource.save
            render json: @user_resource, status: 201, serializer: ::V1::UsersResourceSerializer
          else
            render json: {
              message: 'Could not destroy resource watched request', reasons: @user_resource.errors.full_messages
            }, status: :bad_request
          end
        end

        private

        def set_resource
          @resource = Resource.find(params[:resource_id])
        end

        def set_user_resource
          @user_resource = UsersResource.find_by_resource_id_and_user_id(params[:resource_id], current_user.id)
        end
      end
    end
  end
end
