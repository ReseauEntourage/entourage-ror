module HomeServices
  class Action
    DISTANCE = 10
    MAX_LENGTH = 4
    TIME_RANGE = 24

    attr_reader :user, :latitude, :longitude, :time_range, :distance

    def initialize user:, latitude:, longitude:
      @user = user
      @latitude = latitude
      @longitude = longitude
      @time_range = TIME_RANGE
      @distance = DISTANCE
    end

    def find_all
      return [] unless latitude && longitude

      Entourage.where(status: :open)
        .where.not(group_type: [:conversation, :group, :outing])
        .where("entourages.created_at > ?", time_range.hours.ago)
        .where("(#{Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)}) OR online = true")
        .order_by_distance_from(latitude, longitude)
        .limit(MAX_LENGTH)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end