module HomeServices
  class Headline
    ACTION_CATEGORIES = [:mat_help]
    TIME_RANGE = 24
    MAX_LENGTH = 5

    # currently offer_help, association and default share the same definition
    STRUCTURE = {
      offer_help: {
        active: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        animated: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        dead: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
      },
      association: {
        active: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        animated: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        dead: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
      },
      ask_for_help: {
        active: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        animated: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        dead: [
          { type: :pin, category: :neighborhood },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
      },
      default: {
        active: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        animated: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
        dead: [
          { type: :pin },
          { type: :announcement, offset: 0 },
          { type: :announcement, offset: 1 },
          { type: :announcement, offset: 2 },
          { type: :announcement, category: :online },
        ],
      },
    }

    attr_reader :user, :latitude, :longitude, :time_range, :distance

    def initialize user:, latitude:, longitude:
      @user = user
      @latitude = latitude
      @longitude = longitude
      @time_range = TIME_RANGE
      @distance = UserService.travel_distance(user: user)
    end

    def each
      STRUCTURE[profile][zone].map do |element|
        method = "find_#{element[:type]}".to_sym
        next unless self.class.instance_methods.include?(method)

        name = element[:type].to_s
        name << "_#{element[:category]}" if element[:category].present?
        name << "_#{element[:offset]}" if element[:offset].present?

        {
          name: name.to_sym,
          type: element[:type] == :announcement ? 'Announcement' : 'Entourage',
          instance: send(method, category: element[:category], offset: element[:offset])
        }
      end.filter do |record|
        record[:instance].present?
      end[0..(MAX_LENGTH-1)].each do |record|
        yield record
      end
    end

    def find_pin category: nil, offset: 0
      entourage_id = EntourageServices::Pins.pinned_for(user)
      return unless entourage_id

      Entourage.find_by(id: entourage_id)
    end

    def find_announcement category: nil, offset: 0
      FeedServices::AnnouncementsService.announcements_scope_for_user(user)
        .where(category: category)
        .order(:position)
        .offset(offset)
        .first
    end

    def find_outing category: nil, offset: 0
      return [] unless latitude && longitude

      feeds = user.community.entourages.where(group_type: :outing, status: :open)
        .where("(#{Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)}) OR online = true")
        .where("metadata->>'ends_at' >= ?", Time.zone.now)
        .order("metadata->>'starts_at' asc, id") # DEPRECATION WARNING: metadata->>'starts_at' asc, id". Non-attribute arguments will be disallowed in Rails 6.0. This method should not be called with user-provided values, such as request parameters or model attributes
        .offset(offset)
        .first
    end

    def find_action category: nil, offset: 0
      return [] unless latitude && longitude

      entourages = Entourage.where(status: :open)
        .where.not(group_type: [:conversation, :group, :outing])
        .where("entourages.created_at > ?", time_range.hours.ago)
        .where(pin: false)
        .where("(#{
          Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)
        }) OR online = true")
        .order_by_distance_from(latitude, longitude)
        .order(created_at: :desc)

      return entourages.where(category: category).offset(offset).first if category.present?

      entourages.where(['category not in (?) or category is null', ACTION_CATEGORIES]).offset(offset).first
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

    # @incomplete only returns :dead or :active
    # @incomplete hors_zone includes :animated zones (Bordeaux, Nantes, Marseille, etc.)
    # @fallback when user has no profile, should falls back to GPS coordinates
    # @fixme zone should be computed against action and event existence in the area of the user
    def zone
      departement_slugs = user.departement_slugs

      return :dead if [[:sans_zone], [:hors_zone]].include?(departement_slugs)
      return :dead if (departement_slugs & ModerationArea.slugs).empty?

      :active
    end
  end
end
