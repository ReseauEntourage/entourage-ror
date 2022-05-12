module Api
  module V1
    module Neighborhoods
      class UnauthorizedOuting < StandardError; end

      class OutingsController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :destroy]
        before_action :authorised_to_see_messages?

        rescue_from Api::V1::Neighborhoods::UnauthorizedOuting do |exception|
          render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
        end

        def create
          outing = Entourage.new(outing_params.except(:location))
          outing.user = current_user
          outing.status = :open
          outing.group_type = :outing
          outing.entourage_type = :contribution
          outing.category = :social
          outing.uuid = SecureRandom.uuid
          outing.neighborhoods = [@neighborhood]

          if outing.save
            JoinRequest.create(joinable: outing, user: current_user, role: :organizer).save!

            render json: outing, root: :outing, status: 201, serializer: ::V1::EntourageSerializer, scope: { user: current_user }
          else
            render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
          end
        end

        private

        def outing_params
          params.require(:outing).permit(:title, :description, :event_url, :latitude, :longitude, { metadata: [
            :starts_at,
            :ends_at,
            :place_name,
            :street_address,
            :google_place_id
          ] })
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
      end
    end
  end
end
