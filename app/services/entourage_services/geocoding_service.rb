module EntourageServices
  module GeocodingService
    EARTH_RADIUS = 6371.0

    def self.distance_rounded lat1, lon1, lat2, lon2
      distance = distance(lat1, lon1, lat2, lon2)
      return distance if distance == 0

      magnitude = 10 ** Math.log10(distance.abs).floor

      (distance / magnitude).round(1) * magnitude
    end

    def self.distance lat1, lon1, lat2, lon2
      # Convertir les degrés en radians
      lat1_rad = to_radians(lat1)
      lon1_rad = to_radians(lon1)
      lat2_rad = to_radians(lat2)
      lon2_rad = to_radians(lon2)

      # Différences de latitude et de longitude
      delta_lat = lat2_rad - lat1_rad
      delta_lon = lon2_rad - lon1_rad

      # Formule de Haversine
      a = Math.sin(delta_lat / 2) ** 2 +
          Math.cos(lat1_rad) * Math.cos(lat2_rad) *
          Math.sin(delta_lon / 2) ** 2

      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      # Distance en kilomètres
      EARTH_RADIUS * c
    end

    def self.to_radians(degree)
      degree * Math::PI / 180
    end
    def self.geocode entourage
      country, postal_code, city = search_postal_code(entourage.latitude, entourage.longitude)

      updates = {country: country, postal_code: postal_code}

      if entourage.group_type.in?(['action', 'group'])
        city ||= ''
        updates[:metadata] = entourage.metadata.merge(city: city)
      end

      entourage.update(updates)
    end

    def self.search_postal_code latitude, longitude
      # this will raise in case of an API error
      # see config/initializers/geocoder.rb
      results = Geocoder.search(
        [latitude, longitude],
        params: { result_type: :postal_code }
      )
      result = results.find { |r| r.types.include? 'postal_code' }

      if result.present?
        [result.country_code, result.postal_code, result.city]
      else
        search_approximate_postal_code(latitude, longitude)
      end
    end

    def self.search_approximate_postal_code latitude, longitude
      # try again without specifying a result_type
      results = Geocoder.search([latitude, longitude])
      # and keep the first that has a postal code
      result = results.find { |r| r.postal_code.present? }

      if result.present?
        country = result.country_code
        city = result.city
        postal_code =
          if country == 'FR'
            result.postal_code.first(2) + '000'
          else
            'XXXXX'
          end
      else
        country     = 'XX'
        postal_code = '00000'
        city        = ''
      end

      [country, postal_code, city]
    end

    def self.enable_callback
      !Rails.env.test?
    end

    module Callback
      extend ActiveSupport::Concern

      included do
        after_commit :geocode_async
      end

      private

      def geocode_async
        return unless EntourageServices::GeocodingService.enable_callback
        return unless (['latitude', 'longitude'] & previous_changes.keys).any?
        AsyncService.new(GeocodingService).geocode(self)
      end
    end
  end
end
