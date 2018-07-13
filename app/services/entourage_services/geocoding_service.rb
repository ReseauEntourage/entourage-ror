module EntourageServices
  module GeocodingService
    def self.geocode entourage
      # this will raise in case of an API error
      # see config/initializers/geocoder.rb
      results = Geocoder.search(
        [entourage.latitude, entourage.longitude],
        params: { result_type: :postal_code }
      )
      result = results.find { |r| r.types.include? 'postal_code' }

      if result.nil?
        # try again without specifying a result_type
        results = Geocoder.search([entourage.latitude, entourage.longitude])
        # and keep the first that has a postal code
        result = results.find { |r| r.postal_code.present? }
      end

      if result.nil?
        country     = 'XX'
        postal_code = '00000'
      else
        country     = result.country_code
        postal_code = result.postal_code
      end

      entourage.update(country: country, postal_code: postal_code)
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
