module HomeServices
  class Outing
    DISTANCE = 10
    MAX_LENGTH = 3

    # currently offer_help, association and default share the same definition
    STRUCTURE = {
      offer_help: [
        { offset: 0 },
        { offset: 1 },
        { offset: 2 },
        { category: :online },
      ],
      association: [
        { offset: 0 },
        { offset: 1 },
        { offset: 2 },
        { category: :online },
      ],
      ask_for_help: [
        { offset: 0 },
        { offset: 1 },
        { offset: 2 },
        { category: :contact },
      ],
      default: [
        { offset: 0 },
        { offset: 1 },
        { offset: 2 },
        { category: :online },
      ],
    }

    attr_reader :user, :latitude, :longitude, :distance

    def initialize user:, latitude:, longitude:
      @user = user
      @latitude = latitude
      @longitude = longitude
      @distance = DISTANCE
    end

    def find_all
      STRUCTURE[profile].map do |element|
        find_outing(category: element[:category], offset: element[:offset])
      end.filter do |record|
        record.present?
      end[0..(MAX_LENGTH-1)]
    end

    def find_outing category: nil, offset: 0
      return [] unless latitude && longitude

      outing = user.community.entourages.where(group_type: :outing, status: :open)
        .where("(#{Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)}) OR online = true")
        .where("metadata->>'ends_at' >= ?", Time.zone.now)
        .order("case when online then 1 else 2 end")
        .order_by_distance_from(latitude, longitude)
        .order(created_at: :desc)

      return outing.where(online: true).offset(offset).first if category == :online
      return outing.where(category: category).offset(offset).first if category.present?

      outing.offset(offset).first
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end

    def profile
      return :ask_for_help if user.targeting_profile&.to_sym == :asks_for_help
      return :offer_help if user.targeting_profile&.to_sym == :offers_help

      profile = (user.targeting_profile || user.goal || :default).to_sym

      return :default unless STRUCTURE.keys.include?(profile)

      profile
    end
  end
end