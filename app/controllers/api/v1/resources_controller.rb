module Api
  module V1
    class ResourcesController < Api::V1::BaseController
      before_action :set_resource, only: [:show]
      after_action :set_as_watched, only: [:show]

      def index
        render json: Resource.all, each_serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      def show
        render json: @resource, serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      private

      def set_resource
        @resource = Resource.find(params[:id])
      end

      def set_as_watched
        ResourceServices::Read.new(resource: @resource, user: current_user).set_as_watched_and_save
      end
    end
  end
end
