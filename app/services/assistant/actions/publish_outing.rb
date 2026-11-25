module Assistant
  module Actions
    # Creates an outing in the name of the user with the service of the app
    # (EntourageServices::OutingBuilder), with the same validations as the creation in the app.
    # The title and the description are the ones given by the assistant, untouched but for the
    # normalization of the model.
    #
    # The app needs coordinates, the assistant gives a place as a text: it is geocoded with the geocoder
    # of the app (Assistant::PlaceGeocoder). That text leaves Local for the geocoder (point for the DPO).
    class PublishOuting < Base
      # @param params [Hash] title, description, starts_at, ends_at (both ISO 8601), place (text), reserved_female
      def initialize user:, params:
        super(user: user)
        @params = params
      end

      def call
        require_param!(@params[:title], 'title')
        require_param!(@params[:starts_at], 'startsAt')
        require_param!(@params[:place], 'place')
        place = locate(@params[:place])

        outing = nil
        ::EntourageServices::OutingBuilder.new(params: permitted(place), user: user).create do |on|
          on.success { |created| outing = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_PUBLISH', 'Could not create the outing.') }
        end

        outcome(201, { id: outing.uuid_v2, status: outing.status }, outing)
      end

      private

      def locate text
        ::Assistant::PlaceGeocoder.locate(text)
      rescue ::Assistant::PlaceGeocoder::NotFound
        refuse!(400, 'PLACE_NOT_FOUND', 'This place is not known.')
      end

      def permitted place
        metadata = {
          starts_at: @params[:starts_at], ends_at: @params[:ends_at],
          place_name: @params[:place], street_address: place.address || @params[:place], google_place_id: place.place_id,
          reserved_female: ActiveModel::Type::Boolean.new.cast(@params[:reserved_female]) || false
        }

        ActionController::Parameters.new(
          title: @params[:title], description: @params[:description],
          latitude: place.latitude, longitude: place.longitude, metadata: metadata.compact
        ).permit!
      end
    end
  end
end
