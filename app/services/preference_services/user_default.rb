module PreferenceServices
  class UserDefault
    def initialize(user:)
      @user = user
    end

    def date_range
      $redis.get("preferences:user:#{user.id}:date_range") || ''
    end

    def date_range=(another_date_range)
      $redis.set("preferences:user:#{user.id}:date_range", another_date_range)
    end

    def tour_types
      ($redis.get("preferences:user:#{user.id}:tour_types") || 'medical,barehands,alimentary').split(',')
    end

    def tour_types=(other_tour_types)
      $redis.set("preferences:user:#{user.id}:tour_types", other_tour_types.join(','))
    end

    def simplified_tour
      $redis.get("preferences:user:#{user.id}:simplified_tour") == 'true'
    end

    def simplified_tour=(val)
      bool_value = (val ? 'true' : 'false')
      $redis.set("preferences:user:#{user.id}:simplified_tour", bool_value)
    end

    def latitude
      $redis.get("preferences:user:#{user.id}:latitude").try(:to_f) || 48.866051
    end

    def latitude=(another_latitude)
      $redis.set("preferences:user:#{user.id}:latitude", another_latitude)
    end

    def longitude
      $redis.get("preferences:user:#{user.id}:longitude").try(:to_f) || 2.3565218
    end

    def longitude=(another_longitude)
      $redis.set("preferences:user:#{user.id}:longitude", another_longitude)
    end


    private
    attr_reader :user
  end
end
