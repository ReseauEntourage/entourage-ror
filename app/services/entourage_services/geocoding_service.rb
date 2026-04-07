module EntourageServices
  module GeocodingService
    def self.geocode entourage_id
      return unless entourage = Entourage.find_by_id(entourage_id)

      country, postal_code, city = search_postal_code(entourage.latitude, entourage.longitude)

      updates = {country: country, postal_code: postal_code}

      if entourage.group_type.in?(['action', 'group'])
        city ||= ''
        updates[:metadata] = entourage.metadata.merge(city: city)
      end

      entourage.update(updates)
    end

    def self.get_postal_code latitude, longitude
      return unless latitude.present? && longitude.present?

      EntourageServices::GeocodingService.search_postal_code(latitude, longitude).second
    rescue
      nil
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

        AsyncService.new(GeocodingService).geocode(id)
      end
    end
  end
end
