module PreferenceServices
  class UserDefault
    def initialize(user:)
      @user = user
    end

    def tour_types
      ($redis.get("preferences:user:#{user.id}:tour_types") || "").split(",")
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

    private
    attr_reader :user
  end
end