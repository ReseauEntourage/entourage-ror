module HomeServices
  class Action
    MAX_LENGTH = 7
    TIME_RANGE = 24 * 30

    attr_reader :user, :latitude, :longitude, :time_range, :distance

    def initialize user:, latitude:, longitude:
      @user = user
      @latitude = latitude
      @longitude = longitude
      @time_range = TIME_RANGE
      @distance = UserService.travel_distance(user: user)
    end

    def find_all entourage_type: [:ask_for_help, :contribution]
      return [] unless latitude && longitude

      Entourage.where(status: :open)
        .where.not(group_type: [:conversation, :group, :outing])
        .where('entourages.created_at > ?', time_range.hours.ago)
        .where(entourage_type: entourage_type)
        .where("(#{Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)}) OR online = true")
        .order_by_profile(profile)
        .order_by_distance_from(latitude, longitude)
        .limit(MAX_LENGTH)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end

    def profile
      return :ask_for_help if user.targeting_profile&.to_sym == :asks_for_help
      return :offer_help if user.targeting_profile&.to_sym == :offers_help

      profile = (user.targeting_profile || user.goal || :default).to_sym

      return :default unless [:ask_for_help, :offer_help].include?(profile)

      profile
    end
  end
end
