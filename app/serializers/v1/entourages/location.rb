module V1
  module Entourages
    module Location
      def location
        {
          latitude: randomizer.random_latitude,
          longitude: randomizer.random_longitude
        }
      end

      def randomizer
        @randomizer ||= EntourageServices::EntourageLocationRandomizer.new(entourage: object)
      end
    end
  end
end
