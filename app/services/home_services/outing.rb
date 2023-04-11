module HomeServices
  class Outing
    MAX_LENGTH = 7

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
      @distance = UserService.travel_distance(user: user)
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
        .where(Arel.sql("metadata->>'ends_at' >= '#{Time.zone.now}'"))
        .order(Arel.sql("metadata->>'starts_at'"))

      return outing.where(online: true).offset(offset).first if category == :online
      return outing.where(category: category).offset(offset).first if category.present?

      outing.where(online: false).offset(offset).first
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
