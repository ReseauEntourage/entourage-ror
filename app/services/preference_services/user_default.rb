module PreferenceServices
  class UserDefault
    def initialize(user:)
      @user = user
    end

    def date_range
      $redis.get("preferences:user:#{user.id}:date_range") || ""
    end

    def date_range=(another_date_range)
      $redis.set("preferences:user:#{user.id}:date_range", another_date_range)
    end

    def tour_types
      ($redis.get("preferences:user:#{user.id}:tour_types") || "medical,barehands,alimentary").split(",")
    end

    def tour_types=(other_tour_types)
      $redis.set("preferences:user:#{user.id}:tour_types", other_tour_types.join(","))
    end

    def snap_to_road
      $redis.get("preferences:user:#{user.id}:snap_to_road") == "true"
    end

    def snap_to_road=(val)
      bool_value = (val ? "true" : "false")
      $redis.set("preferences:user:#{user.id}:snap_to_road", bool_value)
    end

    def simplified_tour
      $redis.get("preferences:user:#{user.id}:simplified_tour") == "true"
    end

    def simplified_tour=(val)
      bool_value = (val ? "true" : "false")
      $redis.set("preferences:user:#{user.id}:simplified_tour", bool_value)
    end

    def latitude
      $redis.get("preferences:user:#{user.id}:latitude").try(:to_f)
    end

    def latitude=(another_latitude)
      $redis.set("preferences:user:#{user.id}:latitude", another_latitude)
    end

    def longitude
      $redis.get("preferences:user:#{user.id}:longitude").try(:to_f)
    end

    def longitude=(another_longitude)
      $redis.set("preferences:user:#{user.id}:longitude", another_longitude)
    end


    private
    attr_reader :user
  end
end