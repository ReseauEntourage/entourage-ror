module Api
  module V1
    class OutingsController < Api::V1::BaseController
      def create
        EntourageServices::OutingBuilder.new(params: outing_params, user: current_user).create do |on|
          on.success do |outing|
            render json: outing, root: :outing, status: 201, serializer: ::V1::EntourageSerializer, scope: { user: current_user }
          end

          on.failure do |outing|
            render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
          end
        end
      end

      private

      def outing_params
        params.require(:outing).permit(:title, :description, :event_url, :latitude, :longitude, :other_interest, { metadata: [
          :starts_at,
          :ends_at,
          :place_name,
          :street_address,
          :google_place_id
        ] }, neighborhood_ids: [],
          interests: []
        )
      end
    end
  end
end
