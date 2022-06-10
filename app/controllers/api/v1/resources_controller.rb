module Api
  module V1
    class ResourcesController < Api::V1::BaseController
      before_action :set_resource, only: [:show]

      def index
        render json: Resource.page(page).per(per), each_serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      def show
        render json: @resource, serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      private

      def set_resource
        @resource = Resource.find(params[:id])
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end
    end
  end
end
