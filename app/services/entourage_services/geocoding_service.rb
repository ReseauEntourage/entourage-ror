module EntourageServices
  module GeocodingService
    def self.geocode entourage
      results = Geocoder.search(
        [entourage.latitude, entourage.longitude],
        params: { result_type: :postal_code }
      )
      result = results.find { |r| r.types.include? 'postal_code' }
      entourage.update(
        country:     result.country_code,
        postal_code: result.postal_code
      )
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
