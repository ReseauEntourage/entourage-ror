module Api
  module V1
    module Neighborhoods
      class OutingsController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :destroy]

        def create
          outing = Entourage.new(outing_params.except(:location))
          outing.group_type = :outing
          outing.user = current_user
          outing.uuid = SecureRandom.uuid
          outing.neighborhoods = [@neighborhood]

          if outing.save
            JoinRequest.create(joinable: outing, user: current_user, role: :organizer).save!

            render json: outing, status: 201, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
          else
            render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
          end
        end

        private

        def outing_params
          metadata_keys = params.dig(:outing, :metadata).try(:keys) || [] # security issue
          metadata_keys -= [:starts_at]
          permitted = params.require(:outing).permit(:status, :title, :description, :category, :entourage_type, :latitude, :longitude, :url, :event_url, metadata: metadata_keys)

          [:starts_at, :ends_at].each do |timestamp|
            datetime = params.dig(:outing, :metadata, timestamp)&.slice(:date, :hour, :min)
            if datetime.present?
              permitted[:metadata] ||= {}
              permitted[:metadata][timestamp] = Date.strptime(datetime[:date]).in_time_zone.change(
                hour: datetime[:hour],
                min:  datetime[:min]
              )
            end
          end

          permitted
        end

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end
      end
    end
  end
end
