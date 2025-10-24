module EntourageServices
  class LocationApproximationService
    def initialize(entourage)
      @entourage = entourage
    end

    def approximated_location
      if ENV['DISABLE_ENTOURAGE_GEOCODING']
        ''
      else
        @approximated_location ||=
          cache(cache_key, 30.days, except: '') { formated_location }
      end
    end

    def expire_cache
      $redis.del(cache_key) if cache_key.present?
    end

    private

    def formated_location
      return '' if location.nil?
      "#{location.city}, #{location.postal_code}"
    end

    def location
      @location ||= begin
        coordinates = [@entourage.latitude, @entourage.longitude]
        begin
          # this will raise in case of an API error
          # see config/initializers/geocoder.rb
          Geocoder.search(coordinates).first
        rescue => e
          Rails.logger.error(e)

          nil
        end
      end
    end

    def cache_key
      return if @entourage.id.nil?
      @cache_key ||= "entourages:#{@entourage.id}:approximated_location"
    end

    def cache(key, ttl, options={})
      cached_value = $redis.get(key) unless key.nil?
      return cached_value unless cached_value.nil?

      computed_value = yield
      ignore_value = options.key?(:except) && computed_value == options[:except]
      $redis.setex(key, ttl, computed_value) if !key.nil? && !ignore_value
      computed_value
    end

    module Callback
      extend ActiveSupport::Concern

      included do
        after_commit :expire_approximated_location_cache
      end

      def expire_approximated_location_cache
        return unless (['latitude', 'longitude'] & previous_changes.keys).any?
        LocationApproximationService.new(self).expire_cache
      end
    end
  end
end
