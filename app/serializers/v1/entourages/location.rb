module V1
  module Entourages
    module Location
      def location
        return {
          latitude: randomizer.random_latitude,
          longitude: randomizer.random_longitude
        } if object.is_a?(Entourage) && object.action?

        {
          latitude: object.latitude,
          longitude: object.longitude
        }
      end

      def distance
        return unless scope
        return unless scope[:latitude].present? && scope[:longitude].present?

        Geocoder::Calculations.distance_between(
          [location[:latitude], location[:longitude]],
          [scope[:latitude], scope[:longitude]],
          units: :km
        ).round(1)
      end

      def randomizer
        @randomizer ||= EntourageServices::EntourageLocationRandomizer.new(entourage: object)
      end
    end
  end
end
