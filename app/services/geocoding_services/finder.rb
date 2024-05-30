module GeocodingServices
  class Finder
    class << self
      def get_city_from attributes = {}
        attributes = attributes.symbolize_keys

        if attributes[:google_place_id]
          geocoder = get_geocoder_from_place_id(attributes[:google_place_id])

          return geocoder.city if geocoder
        end

        return unless attributes[:latitude] && attributes[:longitude]
        get_geocoder_from_coordinates(attributes[:latitude], attributes[:longitude]).city
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
