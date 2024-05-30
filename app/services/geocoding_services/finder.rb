module GeocodingServices
  class Finder
    class << self
      def get_city_from attributes = {}
        attributes = attributes.symbolize_keys

        geocoder = if attributes[:google_place_id]
          get_geocoder_from_place_id(attributes[:google_place_id])
        elsif attributes[:latitude] && attributes[:longitude]
          get_geocoder_from_coordinates(attributes[:latitude], attributes[:longitude])
        end

        return unless geocoder

        geocoder.city
      end

      def get_geocoder_from_place_id place_id
        Geocoder.search(place_id,
          lookup: :google_places_details,
          params: {
            region: :fr,
            fields: [
              'geometry/location',
              :name,
              :address_components,
              :place_id,
              :formatted_address
            ].join(',')
          }
        ).first
      end

      def get_geocoder_from_coordinates latitude, longitude
        Geocoder.search([latitude, longitude]).first
      end
    end
  end
end
