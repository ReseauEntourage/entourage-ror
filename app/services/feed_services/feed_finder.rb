module FeedServices
  class FeedFinder

    DEFAULT_DISTANCE=10
    DEFAULT_PER=25

    def initialize(user:,
                   page:,
                   per:,
                   show_tours:,
                   entourage_types:,
                   tour_types:,
                   context:,
                   types: nil,
                   latitude:,
                   longitude:,
                   show_my_entourages_only: "false",
                   show_my_tours_only: "false",
                   show_my_partner_only: "false",
                   show_past_events: "false",
                   time_range: 24,
                   tour_status: nil,
                   entourage_status: nil,
                   before: nil,
                   author: nil,
                   invitee: nil,
                   distance: nil,
                   announcements: nil)
      @user = user
      @page = page
      @per = per || DEFAULT_PER
      @before = before.present? ? (DateTime.parse(before) rescue Time.now) : nil
      @latitude = latitude
      @longitude = longitude
      @show_tours = show_tours
      @feed_type = join_types(entourage_types: entourage_types, tour_types: tour_types)
      @types = formated_types(types) if types != nil
      @context = context.to_sym
      @show_my_entourages_only = show_my_entourages_only=="true"
      @show_my_tours_only = show_my_tours_only=="true"
      @show_my_partner_only = show_my_partner_only=="true"
      @show_past_events = show_past_events=="true"
      @time_range = time_range.to_i
      @tour_status = formated_status(tour_status)
      @entourage_status = formated_status(entourage_status)
      @author = author
      @invitee = invitee
      @distance = [(distance&.to_i || DEFAULT_DISTANCE), 40].min
      @announcements = announcements.try(:to_sym)
      @cursor = nil
      @area = FeedRequestArea.new(@latitude, @longitude)
      @metadata = {}

      @time_range = lyon_grenoble_timerange_workaround
    end

    def feeds
      feeds = user.community.feeds
                  .where.not(status: 'blacklisted')
                  .includes(feedable: [{ user: { default_user_partners: :partner} }])

      if context == :feed
        feeds = feeds.where.not(group_type: :conversation)
      end

      if types != nil
        feeds = feeds.where(feed_category: types)
      else
        feeds = feeds.where(feedable_type: "Entourage") unless (show_tours=="true" && user.pro?)
        feeds = feeds.where(feed_type: feed_type) if feed_type
      end
      feeds = filter_my_feeds_only(feeds: feeds)
      feeds = filter_my_partner_only(feeds: feeds) if show_my_partner_only
      feeds = filter_past_events(feeds: feeds) unless show_past_events
      feeds = feeds.where(user: author) if author
      unless user.community == :pfp
        feeds = feeds.where("feeds.created_at > ?", time_range.hours.ago)
      end
      feeds = feeds.within_bounding_box(box) if latitude && longitude

      if tour_status && entourage_status
        feeds = feeds.where("(feedable_type='Entourage' AND feeds.status IN (?)) OR (feedable_type='Tour' AND feeds.status IN (?))", entourage_status, tour_status)
      elsif tour_status
          feeds = feeds.where("feedable_type='Tour' AND feeds.status IN (?)", tour_status)
      elsif entourage_status
          feeds = feeds.where("feedable_type='Entourage' AND feeds.status IN (?)", entourage_status)
      end

      #If we have both created_by_me filter AND invited_in filter, then we look for created_by_me OR invited_in feeds
      inclusive = author.blank? || invitee.blank?
      feeds = filter_by_invitee(feeds: feeds, inclusive: inclusive)

      feeds = if page && per
        feeds.page(page).per(per)
      elsif latitude && longitude && before
        # extract cursor from `before` parameter
        @cursor = before.to_i if before.year == 1970
        feeds # pagination is handled later for clarity
      elsif before
        feeds.before(before).limit(25)
      else
        feeds.limit(25)
      end

      UserServices::NewsfeedHistory.save(user: user,
                                         latitude: latitude,
                                         longitude: longitude)

      feeds =
        if latitude && longitude
          order_by_distance(feeds: feeds).sort_by(&:updated_at).reverse
        else
          feeds.order("updated_at DESC")
        end

      if latitude && longitude && page == 1
        pinned = Onboarding::V1.pinned_entourage_for area, user: user
        if !pinned.nil?
          feeds = pin(pinned, feeds: feeds)
          @metadata.merge!(onboarding_entourage_pinned: true, area: area)
        end
      end

      feeds = insert_announcements(feeds: feeds) if announcements == :v1

      # if user.community == :entourage && page == 1 && area.in?(['Paris République', 'Paris 17 et 9', 'Paris 15', 'Paris 5'])
      #   feeds = pin(4243, feeds: feeds)
      # end

      preload_user_join_requests(feeds)
      preload_entourage_moderations(feeds)
      preload_tour_user_organizations(feeds)
      preload_chat_messages_counts(feeds)

      cursor = Time.at(cursor + 1).as_json if !cursor.nil?
      FeedWithCursor.new(feeds, cursor: cursor, metadata: @metadata)
    end

    private
    attr_reader :user, :page, :per, :before, :latitude, :longitude, :show_tours, :feed_type, :types, :context, :show_my_entourages_only, :show_my_tours_only, :show_my_partner_only, :show_past_events, :time_range, :tour_status, :entourage_status, :author, :invitee, :distance, :announcements, :cursor, :area

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          distance,
                                          units: :km)
    end

    def join_types(entourage_types:, tour_types:)
      entourage_types = formated_type(entourage_types) || Entourage::ENTOURAGE_TYPES
      tour_types = formated_type(tour_types) || Tour::TOUR_TYPES
      entourage_types + tour_types
    end

    def formated_type(types)
      types&.gsub(" ", "")&.split(",")
    end

    TYPES = {
      'entourage' => {
        'as' => 'ask_for_help_social',
        'ae' => 'ask_for_help_event',
        'am' => 'ask_for_help_mat_help',
        'ar' => 'ask_for_help_resource',
        'ai' => 'ask_for_help_info',
        'ak' => 'ask_for_help_skill',
        'ao' => 'ask_for_help_other',

        'cs' => 'contribution_social',
        'ce' => 'contribution_event',
        'cm' => 'contribution_mat_help',
        'cr' => 'contribution_resource',
        'ci' => 'contribution_info',
        'ck' => 'contribution_skill',
        'co' => 'contribution_other',

        # fix wrong keys in iOS 4.1 - 4.3
        'ah' => 'ask_for_help_mat_help',
        'ch' => 'contribution_mat_help',
      },
      'entourage_pro' => {
        'tm' => 'tour_medical',
        'tb' => 'tour_barehands',
        'ta' => 'tour_alimentary',

        # fix wrong key in iOS 4.1 - 4.3
        'ts' => 'tour_barehands',
      },
      'pfp' => {
        'nh' => 'neighborhood',
        'pc' => 'private_circle',
        'ou' => 'outing',
      }
    }

    def formated_types(types)
      allowed_types = TYPES[user.community.slug]
      allowed_types.merge!(TYPES['entourage_pro']) if user.pro?

      types = (types || "").split(',').map(&:strip)
      types = types.map { |t| allowed_types[t] || t }

      (types & allowed_types.values).uniq
    end

    def formated_status(status)
      [status].flatten if status
    end

    def filter_my_feeds_only(feeds:)
      if show_my_entourages_only && show_my_tours_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.user_id = #{user.id}  AND join_requests.status <> 'cancelled') OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.user_id = #{user.id}) AND join_requests.status='accepted')")
      elsif show_my_entourages_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.status='accepted' AND join_requests.user_id = #{user.id}) OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.user_id = #{user.id}))")
      elsif show_my_tours_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.user_id = #{user.id}) OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.status='accepted' AND join_requests.user_id = #{user.id}))")
      end
      feeds
    end

    def filter_my_partner_only(feeds:)
      partner_id = user.default_partner_id

      return feeds if partner_id.nil?

      feeds
        .joins(user: :user_partners)
        .merge(UserPartner.where(default: true, partner_id: partner_id))
    end

    def filter_past_events(feeds:)
      feeds.where("(group_type not in (?) or metadata->>'starts_at' >= ?)", [:outing], Time.now)
    end

    def filter_by_invitee(feeds:, inclusive:)
      return feeds unless invitee

      feeds = feeds.joins("#{join_type(inclusive)} entourage_invitations ON ((entourage_invitations.invitable_type='Entourage' AND feeds.feedable_type='Entourage' AND entourage_invitations.invitable_id=feeds.feedable_id AND entourage_invitations.status='accepted') OR (entourage_invitations.invitable_type='Tour' AND feeds.feedable_type='Tour' AND entourage_invitations.invitable_id=feeds.feedable_id  AND entourage_invitations.status='accepted')  AND entourage_invitations.invitee_id=#{invitee.id})")
      feeds
    end

    def join_type(inclusive)
      inclusive ? "INNER JOIN" : "LEFT OUTER JOIN"
    end

    def insert_announcements(feeds:)
      feeds, announcements_metadata = AnnouncementsService.new(
        feeds: feeds,
        user: user,
        page: page,
        area: area
      ).feeds

      @metadata.merge!(announcements_metadata)

      feeds
    end

    def order_by_distance(feeds:)
      center   = "ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326)"
      feedable = "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)"
      feeds = feeds
        .select(%{
          feeds.*,
          ST_Distance(#{center}, #{feedable}, false) as distance
        })
        .order("#{center} <-> #{feedable}")

      # the `<->` operator is fast but gives only an approximate ordering
      # so we overshoot a bit, then re-sort and paginate manually
      @cursor ||= 1
      @page = cursor
      feeds = feeds.limit(25 * cursor + 5)
                   .sort_by(&:distance)
                   .drop((cursor - 1) * 25)
                   .take(25)
    end

    def pin entourage_id, feeds:
      feeds = feeds.to_a

      index = feeds.index { |f| f.feedable_type == 'Entourage' && f.feedable_id == entourage_id }

      if index != nil
        item = feeds.delete_at(index)
      else
        item = Announcement::Feed.new(Entourage.find_by(id: entourage_id))
      end

      if item.feedable.nil?
        feeds
      else
        feeds.insert(0, item)
      end
    end

    def lyon_grenoble_timerange_workaround
      return time_range if time_range != 192 # only workaround the '8 days' setting
      return time_range if latitude.nil? || longitude.nil?


      if area.in?(['Lyon Est', 'Lyon Ouest', 'Grenoble'])
        720 # 30 days
      else
        time_range
      end
    end

    def preload_user_join_requests(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(joinable_type = ? and joinable_id in (?))"]
      user_join_requests = user.join_requests
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      user_join_requests =
        Hash[user_join_requests.map { |r| [[r.joinable_type, r.joinable_id], r] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.current_join_request =
          user_join_requests[[feed.feedable_type, feed.feedable_id]]
      end
    end

    def preload_entourage_moderations(feeds)
      entourage_ids = feeds.find_all { |feed| feed.feedable.is_a?(Entourage) && feed.feedable.has_outcome? }.map(&:feedable_id)
      return if entourage_ids.empty?
      entourage_moderations = EntourageModeration.where(entourage_id: entourage_ids)
      entourage_moderations = Hash[entourage_moderations.map { |m| [m.entourage_id, m] }]
      feeds.each do |feed|
        next unless feed.feedable.is_a?(Entourage) && feed.feedable.has_outcome?
        feed.feedable.association(:moderation).target = entourage_moderations[feed.feedable_id]
      end
    end

    def preload_tour_user_organizations(feeds)
      organization_ids = feeds.find_all { |feed| feed.feedable.is_a?(Tour) }.map { |feed| feed.feedable.user.organization_id }.uniq
      return if organization_ids.empty?
      organizations = Organization.where(id: organization_ids)
      organizations = Hash[organizations.map { |o| [o.id, o] }]
      feeds.each do |feed|
        next unless feed.feedable.is_a?(Tour)
        feed.feedable.user.organization = organizations[feed.feedable.user.organization_id]
      end
    end

    def preload_chat_messages_counts(feeds)
      user_join_request_ids = feeds.map { |feed| feed.try(:current_join_request)&.id }
      counts = JoinRequest
        .with_unread_messages
        .where(id: user_join_request_ids)
        .group(:id)
        .count
      counts.default = 0
      feeds.each do |feed|
        join_request_id = feed.try(:current_join_request)&.id
        next if join_request_id.nil?
        feed.number_of_unread_messages = counts[join_request_id]
      end
    end
  end

  # lazily evaluates if the coordinates are inside one of the pre-defined areas
  # returns a String (name of the area or UNKNOWN_AREA)
  class FeedRequestArea < BasicObject
    # the areas are circles: lat,lng define the center, radius is in km
    # coeff is for the length of a degree of longitude depending on the latitude
    # area[:coeff] = Math.cos(area[:lat] * (::Math::PI / 180)).round(5)
    # see: http://jonisalonen.com/2014/computing-distance-between-coordinates-can-be-simple-and-fast/
    AREAS = [
      { name: 'Clichy Levallois',     lat: 48.9,    lng:  2.2833, radius:  2.0, coeff: 0.65738 },
      { name: 'Marseille',            lat: 43.2967, lng:  5.3764, radius: 10.0, coeff: 0.72781 },
      { name: 'Toulouse',             lat: 43.6,    lng:  1.4333, radius: 10.0, coeff: 0.72417 },
      { name: 'Nice',                 lat: 43.7,    lng:  7.25,   radius: 10.0, coeff: 0.72297 },
      { name: 'Nantes',               lat: 47.2167, lng: -1.55,   radius: 10.0, coeff: 0.67923 },
      { name: 'Strasbourg',           lat: 48.5833, lng:  7.75,   radius: 10.0, coeff: 0.66153 },
      { name: 'Montpellier',          lat: 43.6,    lng:  3.8833, radius: 10.0, coeff: 0.72417 },
      { name: 'Bordeaux',             lat: 44.8333, lng: -0.5667, radius: 10.0, coeff: 0.70916 },
      { name: 'Lille',                lat: 50.6333, lng:  3.0667, radius: 10.0, coeff: 0.63428 },
      { name: 'Rennes',               lat: 48.0833, lng: -1.6833, radius: 10.0, coeff: 0.66805 },
      { name: 'Reims',                lat: 49.25,   lng:  4.0333, radius: 10.0, coeff: 0.65276 },
      { name: 'Le Havre',             lat: 49.5,    lng:  0.1333, radius: 10.0, coeff: 0.64945 },
      { name: 'Saint-Étienne',        lat: 45.4333, lng:  4.4,    radius: 10.0, coeff: 0.70174 },
      { name: 'Toulon',               lat: 43.1167, lng:  5.9333, radius: 10.0, coeff: 0.72996 },
      { name: 'Grenoble',             lat: 45.1667, lng:  5.7167, radius: 10.0, coeff: 0.70505 },
      { name: 'Dijon',                lat: 47.3167, lng:  5.0167, radius: 10.0, coeff: 0.67795 },
      { name: 'Angers',               lat: 47.4667, lng: -0.55,   radius: 10.0, coeff: 0.67602 },
      { name: 'Nîmes',                lat: 43.8333, lng:  4.35,   radius: 10.0, coeff: 0.72136 },
      { name: 'Aix-en-Provence',      lat: 43.5333, lng:  5.4333, radius: 10.0, coeff: 0.72497 },
      { name: 'Saint-Denis 93',       lat: 48.9333, lng:  2.3583, radius: 10.0, coeff: 0.65694 },
      { name: 'Versailles',           lat: 48.8,    lng:  2.1333, radius: 10.0, coeff: 0.65869 },
      { name: 'Boulogne-Billancourt', lat: 48.8333, lng:  2.25,   radius:  2.0, coeff: 0.65825 },
      { name: 'Nanterre',             lat: 48.9,    lng:  2.2,    radius:  2.0, coeff: 0.65738 },
      { name: 'Courbevoie',           lat: 48.8973, lng:  2.2522, radius:  2.0, coeff: 0.65741 },
      { name: 'Antony',               lat: 48.75,   lng:  2.3,    radius:  5.0, coeff: 0.65935 },
      { name: 'Lyon Ouest',           lat: 45.7725, lng:  4.8158, radius:  5.0, coeff: 0.69768 },
      { name: 'Lyon Est',             lat: 45.7470, lng:  4.8550, radius:  5.0, coeff: 0.69768 },
      { name: 'Paris République',     lat: 48.8661, lng:  2.3565, radius:  3.0, coeff: 0.65782 },
      { name: 'Paris 17 et 9',        lat: 48.8818, lng:  2.314,  radius:  3.0, coeff: 0.65761 },
      { name: 'Paris 15',             lat: 48.8426, lng:  2.2812, radius:  3.0, coeff: 0.65813 },
      { name: 'Paris 5',              lat: 48.8593, lng:  2.3266, radius:  3.0, coeff: 0.65791 },
    ]
    UNKNOWN_AREA = 'UNKNOWN_AREA'.freeze
    KM_PER_DEG = 110.25

    def initialize lat, lng
      @lat = lat
      @lng = lng
      @evaluated = false
    end

    def method_missing(method_name, *args, &block)
      _area.send(method_name, *args, &block)
    end

    def == other
      _area == other
    end

    def present?
      _area != UNKNOWN_AREA
    end

    def blank?; !present?; end
    def empty?; !present?; end
    def !;      !present?; end

    private

    def respond_to_missing? method_name, include_private=false
      _area.send(:respond_to_missing?, method_name, include_private)
    end

    def _area
      @area ||= begin
        @lat = @lat.to_f
        @lng = @lng.to_f
        area, distance = AREAS
          .map { |a| [a, _distance(a[:lat], a[:lng], a[:coeff])] }
          .sort_by { |_, distance| distance }
          .first

        if area.nil? || distance > area[:radius]
          UNKNOWN_AREA
        else
          area[:name]
        end
      end
    end

    def _distance(lat, lng, coeff)
      x = @lat - lat
      y = (@lng - lng) * coeff
      KM_PER_DEG * ::Math.sqrt(x**2 + y**2)
    end
  end

  class FeedWithCursor
    def initialize entries, cursor:, metadata:{}
      @cursor = cursor
      @entries = entries
      @metadata = metadata
    end

    attr_reader :entries, :cursor, :metadata
  end
end
