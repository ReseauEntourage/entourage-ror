module FeedServices
  class FeedFinder

    DEFAULT_DISTANCE=10
    ITEMS_PER_PAGE=25

    LAST_PAGE_CURSOR = 0xff

    def initialize(user:,
                   latitude:,
                   longitude:,
                   types: nil,
                   show_past_events: "false",
                   time_range: 24,
                   distance: nil,
                   announcements: nil,
                   page_token: nil,
                   legacy_pagination:,
                   before: nil)
      @user = user
      @latitude = latitude
      @longitude = longitude
      @types = formated_types(types)
      @show_past_events = show_past_events=="true"
      @time_range = time_range.to_i
      @distance = [(distance&.to_i || DEFAULT_DISTANCE), 40].min
      @announcements = announcements.try(:to_sym)
      @page_token = page_token

      @legacy_pagination = legacy_pagination
      @before = before.present? ? (DateTime.parse(before) rescue Time.now) : nil

      @time_range = lyon_grenoble_timerange_workaround

      @page = nil
      @last_page = false
      @metadata = {}
    end

    def feeds
      begin
        @latitude  = Float(latitude)
        @longitude = Float(longitude)
      rescue
        raise Api::V1::ApiError, "Invalid latitude/longitude."
      end

      @area = FeedRequestArea.new(@latitude, @longitude)

      if page_token.present?
        @page = self.class.decode_page_token(params_sig: params_sig, token: page_token)
        raise Api::V1::ApiError, "Invalid page token." if page.nil?

      elsif before
        # extract cursor from `before` parameter
        if before.year <= 1970
          @page = before.to_i
        else
          @page = 1
        end

        if page == LAST_PAGE_CURSOR
          return FeedWithCursor.new([], cursor: nil, next_page_token: nil)
        end

      else
        @page = 1
      end

      if page == 1 && !user.anonymous?
        UserServices::NewsfeedHistory.save(user: user,
                                           latitude: latitude,
                                           longitude: longitude)
      end

      feeds = user.community.feeds

      feeds = feeds.where.not(status: [:blacklisted, :suspended])

      feeds = feeds.where.not(group_type: :conversation)
      feeds = feeds
        .joins(%(
          left join entourage_moderations on
            feedable_type = 'Entourage' and
            entourage_moderations.entourage_id = feedable_id
        ))
        .where(%(
          feeds.status != 'closed' or
          feedable_type = 'Tour' or
          (group_type = 'action' and entourage_moderations.action_outcome in ('Oui'))
        ))

      if types != nil
        feeds = feeds.where(feed_category: types)
      elsif !user.pro?
        feeds = feeds.where(feedable_type: "Entourage")
      end

      unless show_past_events
        feeds = feeds.where("group_type not in (?) or metadata->>'ends_at' >= ?", [:outing], Time.zone.now)
      end

      # actions are filtered out based on update date
      feeds = feeds.where("group_type not in (?) or feeds.updated_at >= ?", [:action, :tour], time_range.hours.ago)

      feeds = feeds.within_bounding_box(box)

      feeds = order_by_distance(feeds: feeds)
      feeds = feeds.page(page).per(per)

      feeds = feeds.preload(feedable: {user: :partner})

      feeds = feeds.sort_by(&:created_at).reverse
      # Note: feeds is now an Array.

      # detect if this was the last page (less items than requested)
      if feeds.count < per
        @last_page = true
      end

      if user.community == :entourage && page == 1
      #   pinned = Onboarding::V1.pinned_entourage_for area, user: user
      #   if !pinned.nil?
      #     feeds = pin(pinned, feeds: feeds)
      #     @metadata.merge!(onboarding_entourage_pinned: true, area: area)
      #   end
      #

        case area
        when 'Paris République', 'Paris 17 et 9', 'Paris 15', 'Paris 5', 'Paris'
          feeds = pin(45922, feeds: feeds)
        when 'Lille'
          feeds = pin(45905, feeds: feeds)
        when 'Rennes'
          feeds = pin(45880, feeds: feeds)
        when 'Lyon Ouest', 'Lyon Est', 'Lyon'
          feeds = pin(45876, feeds: feeds)
        when 'La Défense'
          feeds = pin(45904, feeds: feeds)
        end
      end

      feeds = insert_announcements(feeds: feeds) if announcements == :v1

      preload_user_join_requests(feeds)
      preload_entourage_moderations(feeds)
      preload_tour_user_organizations(feeds)
      preload_chat_messages_counts(feeds)

      next_cursor =
        if !legacy_pagination
          nil
        elsif @last_page
          Time.at(LAST_PAGE_CURSOR).as_json
        else
          Time.at(page + 1).as_json
        end

      next_page_token =
        if @last_page
          nil
        else
          self.class.generate_page_token(params_sig: params_sig, cursor: page + 1)
        end

      FeedWithCursor.new(
        feeds,
        cursor: next_cursor,
        next_page_token: next_page_token,
        metadata: @metadata
      )
    end

    def params
      {
        user: UserService.external_uuid(user),
        types: types,
        latitude: latitude,
        longitude: longitude,
        show_past_events: show_past_events,
        time_range: time_range,
        distance: distance,
        announcements: announcements,
      }
    end

    def params_sig
      @params_sig ||= Digest::MD5.hexdigest(JSON.fast_generate(params))
    end

    def self.reformat_legacy_types(entourage_types, show_tours, tour_types)
      if entourage_types.nil?
        entourage_types = Entourage::ENTOURAGE_TYPES
      else
        entourage_types = entourage_types.gsub(' ', '').split(',') & Entourage::ENTOURAGE_TYPES
      end

      entourage_types = entourage_types.flat_map do |entourage_type|
        prefix = "#{entourage_type}_"
        TYPES['entourage'].values.find_all { |type| type.starts_with?(prefix) }
      end

      if show_tours != "true"
        tour_types = []
      elsif tour_types.nil?
        tour_types = Tour::TOUR_TYPES
      else
        tour_types = tour_types.gsub(' ', '').split(',') & Tour::TOUR_TYPES
      end

      tour_types = tour_types.map { |tour_type| "tour_#{tour_type}" }

      return (entourage_types + tour_types).join(",").presence
    end

    private
    attr_reader :user, :page, :before, :latitude, :longitude, :types, :show_past_events, :time_range, :distance, :announcements, :cursor, :area, :page_token, :legacy_pagination

    def self.per
      ITEMS_PER_PAGE
    end
    def per; self.class.per; end

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          distance,
                                          units: :km)
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

        'ou' => 'outing',
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
      return if types.nil?

      allowed_types = TYPES[user.community.slug]
      allowed_types.merge!(TYPES['entourage_pro']) if user.pro?

      types = (types || "").split(',').map(&:strip)
      types = types.map { |t| allowed_types[t] || t }

      types += ['ask_for_help_event', 'contribution_event'] if types.include?('outing')

      (types & allowed_types.values).uniq
    end

    def insert_announcements(feeds:)
      return feeds unless page.is_a?(Integer) && page > 0 && per.is_a?(Integer)
      feeds, announcements_metadata = AnnouncementsService.new(
        feeds: feeds,
        user: user,
        offset: (page - 1) * per,
        area: area,
        last_page: @last_page,
      ).feeds

      @metadata.merge!(announcements_metadata)

      feeds
    end

    def order_by_distance(feeds:)
      distance_from_center = PostgisHelper.distance_from(latitude, longitude)
      feeds.order(distance_from_center, created_at: :desc)
    end

    def pin entourage_id, feeds:
      feeds = feeds.to_a

      index = feeds.index { |f| f.feedable_type == 'Entourage' && f.feedable_id == entourage_id }

      if index != nil
        item = feeds.delete_at(index)
      else
        item = Announcement::Feed.new(Entourage.visible.find_by(id: entourage_id))
      end

      if item.feedable.nil?
        feeds
      else
        feeds.insert(0, item)
      end
    end

    def lyon_grenoble_timerange_workaround
      return time_range if time_range != 192 # only workaround the '8 days' setting


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
      organization_ids = feeds.find_all { |feed| feed.feedable.is_a?(Tour) }.map { |feed| feed.feedable.user&.organization_id }.compact.uniq
      return if organization_ids.empty?
      organizations = Organization.where(id: organization_ids)
      organizations = Hash[organizations.map { |o| [o.id, o] }]
      feeds.each do |feed|
        next unless feed.feedable.is_a?(Tour)
        next if feed.feedable.user.nil?
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

    def preload_last_chat_messages(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        join_request_status = feed.try(:current_join_request)&.status
        next unless join_request_status == 'accepted'
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(messageable_type = ? and messageable_id in (?))"]
      last_chat_messages = ChatMessage
        .select("distinct on (messageable_type, messageable_id) messageable_type, messageable_id")
        .order("messageable_type, messageable_id, created_at desc")
        .select(:id, :content, :user_id, :created_at)
        .includes(:user)
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      last_chat_messages =
        Hash[last_chat_messages.map { |m| [[m.messageable_type, m.messageable_id], m] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.last_chat_message =
          last_chat_messages[[feed.feedable_type, feed.feedable_id]]
      end
    end

    def preload_last_join_requests(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        join_request_status = feed.try(:current_join_request)&.status
        next unless join_request_status == 'accepted'
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(joinable_type = ? and joinable_id in (?))"]
      last_join_requests = JoinRequest
        .select("distinct on (joinable_type, joinable_id) joinable_type, joinable_id")
        .order("joinable_type, joinable_id, created_at desc")
        .select(:id, :status, :user_id, :created_at)
        .where(status: :pending)
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      last_join_requests =
        Hash[last_join_requests.map { |r| [[r.joinable_type, r.joinable_id], r] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.last_join_request =
          last_join_requests[[feed.feedable_type, feed.feedable_id]]
      end
    end

    # This is just for the sake of making the cursor seemingly random and hard
    # to decode, to discourage clients of caching tokens or forging them.
    def self.encode_cursor cursor
      raise ArgumentError unless cursor.in?(0..0xff)
      random_a, random_b = SecureRandom.bytes(2).unpack('C*')
      mask = random_a ^ random_b
      masked_cursor = cursor ^ mask
      bytes = [random_a, random_b, masked_cursor]
      cursor_bytes = bytes.pack('C*')
    end

    def self.decode_cursor cursor_bytes
      bytes = cursor_bytes.unpack('C*')
      return if bytes.count != 3
      random_a, random_b, masked_cursor = bytes
      mask = random_a ^ random_b
      cursor = masked_cursor ^ mask
    end

    def self.generate_page_token params_sig:, cursor:
      short_params_sig = params_sig.to_str.first(8)
      cursor_bytes = encode_cursor(cursor)
      payload = [short_params_sig, cursor_bytes].join('.')
      Base64.urlsafe_encode64(payload, padding: false)
    end

    def self.parse_page_token token
      payload = Base64.urlsafe_decode64(token.to_str)
      short_params_sig, cursor_bytes = payload.split('.', 2)
    rescue
      []
    end

    def self.decode_page_token params_sig:, token:
      short_params_sig, cursor_bytes = parse_page_token(token)
      return nil if short_params_sig != params_sig.first(8)
      cursor = decode_cursor(cursor_bytes)
    end
  end

  # lazily evaluates if the coordinates are inside one of the pre-defined areas
  # returns a String (name of the area or UNKNOWN_AREA)
  class FeedRequestArea < BasicObject
    # the areas are circles: lat,lng define the center, radius is in km
    # coeff is for the length of a degree of longitude depending on the latitude
    # area[:coeff] = Math.cos(area[:lat] * (::Math::PI / 180)).round(5)
    # see: http://jonisalonen.com/2014/computing-distance-between-coordinates-can-be-simple-and-fast/
    #
    # to plot: https://www.calcmaps.com/map-radius/
    AREAS = [
      { name: 'La Défense',           lat: 48.8918, lng:  2.2384, radius:  1.2, coeff: 0.65748 },
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
      { name: 'Paris',                lat: 48.8593, lng:  2.3522, radius: 20.0, coeff: 0.65791 },
      { name: 'Lyon',                 lat: 45.7602, lng:  4.8521, radius: 20.0, coeff: 0.69766 },
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

    def to_str
      _area
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
end
