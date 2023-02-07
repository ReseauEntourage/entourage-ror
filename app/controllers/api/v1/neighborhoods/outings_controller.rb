module Api
  module V1
    module Neighborhoods
      class UnauthorizedOuting < StandardError; end

      class OutingsController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :destroy]
        before_action :authorised_to_see_messages?, only: [:create, :destroy]

        rescue_from Api::V1::Neighborhoods::UnauthorizedOuting do |exception|
          render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
        end

        def index
          render json: @neighborhood.outings.active.future_or_recently_past.page(page).per(per), root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
            user: current_user
          }
        end

        def create
          EntourageServices::OutingBuilder.new(params: outing_params, user: current_user).create do |on|
            on.success do |outing|
              render json: outing, root: :outing, status: 201, serializer: ::V1::OutingSerializer, scope: { user: current_user }
            end

            on.failure do |outing|
              render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
            end
          end
        end

        def destroy
          # to be done
        end

        private

        def outing_params
          params.require(:outing).permit(:title, :description, :event_url, :latitude, :longitude, :other_interest, :recurrency, { metadata: [
            :starts_at,
            :ends_at,
            :place_name,
            :street_address,
            :google_place_id,
            :place_limit
          ] }, interests: []).merge({ neighborhood_ids: @neighborhood.id })
        end

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
        end

        def authorised_to_see_messages?
          raise Api::V1::Neighborhoods::UnauthorizedOuting unless join_request
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
end
