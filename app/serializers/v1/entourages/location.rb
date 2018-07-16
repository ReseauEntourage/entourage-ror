module V1
  module Entourages
    module Location
      def location
        case object.group_type
        when 'outing'
          {
            latitude: object.latitude,
            longitude: object.longitude
          }
        else
          {
            latitude: randomizer.random_latitude,
            longitude: randomizer.random_longitude
          }
        end
      end

      def randomizer
        @randomizer ||= EntourageServices::EntourageLocationRandomizer.new(entourage: object)
      end
    end
  end
end
