module EntourageServices
  class LocationApproximationService
    def initialize(entourage)
      @entourage = entourage
    end

    def approximated_location
      @approximated_location ||=
        cache(cache_key, 30.days, except: '') { formated_location }
    end

    private

    def formated_location
      return '' if location.nil?
      "#{location.city}, #{location.postal_code}"
    end

    def location
      @location ||= begin
        coordinates = [@entourage.latitude, @entourage.longitude]
        Geocoder.search(coordinates).first
      end
    end

    def cache_key
      return if @entourage.id.nil?
      "entourages:#{@entourage.id}:approximated_location"
    end

    def cache(key, ttl, options={})
      cached_value = $redis.get(key) unless key.nil?
      return cached_value unless cached_value.nil?

      computed_value = yield
      ignore_value = options.key?(:except) && computed_value == options[:except]
      $redis.setex(key, ttl, computed_value) if !key.nil? && !ignore_value
      computed_value
    end
  end
end
