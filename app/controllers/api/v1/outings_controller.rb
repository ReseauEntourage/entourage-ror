module Api
  module V1
    class OutingsController < Api::V1::BaseController
      before_action :set_outing, only: [:show, :update, :batch_update, :duplicate]
      before_action :authorised?, only: [:update, :batch_update]
      before_action :allowed_duplicate?, only: [:duplicate]

      def index
        render json: Outing.future.order_by_starts_at.page(page).per(per), root: :outings, each_serializer: ::V1::NeighborhoodOutingSerializer, scope: {
          user: current_user
        }
      end

      def create
        EntourageServices::OutingBuilder.new(params: outing_params, user: current_user).create do |on|
          on.success do |outing|
            render json: outing, root: :outing, status: 201, serializer: ::V1::NeighborhoodOutingSerializer, scope: { user: current_user }
          end

          on.failure do |outing|
            render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
          end
        end
      end

      def update
        EntourageServices::EntourageBuilder.new(params: outing_params, user: current_user).update(entourage: @outing) do |on|
          on.success do |outing|
            render json: outing, status: 200, serializer: ::V1::NeighborhoodOutingSerializer, scope: { user: current_user }
          end

          on.failure do |outing|
            render json: { message: 'Could not update outing', reasons: outing.errors.full_messages }, status: 400
          end
        end
      end

      def batch_update
        @outings = @outing.future_siblings

        errors = nil

        ApplicationRecord.transaction do
          @outings.each do |outing|
            EntourageServices::EntourageBuilder.new(params: outing_params, user: current_user).update(entourage: outing) do |on|
              on.failure do |outing|
                errors = outing.errors.full_messages and raise ActiveRecord::Rollback
              end
            end
          end
        end

        if errors.present?
          render json: { message: 'Could not update outing', reasons: errors }, status: 400
        else
          render json: @outings, status: 200, each_serializer: ::V1::NeighborhoodOutingSerializer, scope: { user: current_user }
        end
      end

      def show
        render json: @outing, serializer: ::V1::NeighborhoodOutingSerializer, scope: { user: current_user }
      end

      def siblings
        render json: Outing.siblings.order_by_starts_at.page(page).per(per), root: :outings, each_serializer: ::V1::NeighborhoodOutingSerializer, scope: {
          user: current_user
        }
      end

      def duplicate
        duplicate = @outing.dup

        if duplicate.save
          render json: duplicate, serializer: ::V1::NeighborhoodOutingSerializer, scope: { user: current_user }
        else
          render json: { message: 'Could not duplicate outing', reasons: duplicate.errors.full_messages }, status: 400
        end
      end

      private

      def set_outing
        @outing = Outing.find(params[:id])
      end

      def outing_params
        params.require(:outing).permit(:title, :description, :event_url, :latitude, :longitude, :other_interest, :online, :recurrency, :entourage_image_id, { metadata: [
          :starts_at,
          :ends_at,
          :place_name,
          :street_address,
          :google_place_id,
          :place_limit
        ] }, neighborhood_ids: [],
          interests: []
        )
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end

      def authorised?
        unless @outing.user == current_user
          render json: { message: 'unauthorized user' }, status: :unauthorized
        end
      end

      def allowed_duplicate?
        unless current_user == Outing.find(params[:id]).user
          render json: { message: 'unauthorized user' }, status: :unauthorized
        end

        unless Outing.find(params[:id]).recurrence.present?
          render json: { message: 'no recurrency settings' }, status: :unauthorized
        end
      end
    end
  end
end
