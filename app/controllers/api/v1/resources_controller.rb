module Api
  module V1
    class ResourcesController < Api::V1::BaseController
      before_action :set_resource, only: [:show]
      before_action :set_resource_from_tag, only: [:tag]
      after_action :set_as_watched, only: [:show, :tag]

      def index
        render json: Resource.all.includes(:translation), each_serializer: ::V1::ResourceSerializer, scope: { user: current_user, nohtml: params[:nohtml].present? }
      end

      def home
        render json: Resource.pin(current_user).includes(:translation), each_serializer: ::V1::ResourceSerializer, scope: { user: current_user, nohtml: params[:nohtml].present? }
      end

      def show
        render json: @resource, serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      def tag
        render json: @resource, serializer: ::V1::ResourceSerializer, scope: { user: current_user }
      end

      private

      def set_resource
        @resource = Resource.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find resource' }, status: 400 unless @resource.present?
      end

      def set_resource_from_tag
        @resource = Resource.find_by_tag(params[:tag])

        render json: { message: 'Could not find resource' }, status: 400 unless @resource.present?
      end

      def set_as_watched
        ResourceServices::Read.new(resource: @resource, user: current_user).set_as_watched_and_save
      end
    end
  end
end
