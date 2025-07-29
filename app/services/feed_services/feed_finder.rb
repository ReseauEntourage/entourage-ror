require 'geocoder/sql'

module FeedServices
  class FeedFinder
    include FeedServices::Preloader

    ITEMS_PER_PAGE=25

    LAST_PAGE_CURSOR = 0xff

    def initialize(user:,
                   latitude:,
                   longitude:,
                   types: nil,
                   show_past_events: 'false',
                   partners_only: 'false',
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
      @show_past_events = show_past_events=='true'
      @partners_only = partners_only=='true'
      @time_range = time_range.to_i
      @distance = UserService.travel_distance(user: user, forced_distance: distance)
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
        raise Api::V1::ApiError, 'Invalid latitude/longitude.'
      end

      @area = FeedServices::FeedRequestArea.new(@latitude, @longitude)

      if page_token.present?
        @page = self.class.decode_page_token(params_sig: params_sig, token: page_token)
        raise Api::V1::ApiError, 'Invalid page token.' if page.nil?

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

      feeds = user.community.feeds

      feeds = feeds.where.not(status: [:blacklisted, :suspended, :full])

      feeds = feeds.where.not(group_type: [:conversation, :group])

      feeds = feeds.where(%(feeds.status != 'closed'))

      if types != nil
        feeds = feeds.where(feed_category: types)
      elsif !user.pro?
        feeds = feeds.where(feedable_type: 'Entourage')
      end

      unless show_past_events
        feeds = feeds.where("group_type not in (?) or metadata->>'ends_at' >= ?", [:outing], Time.zone.now)
      end

      if partners_only
        feeds = feeds.joins(:user).where("users.partner_id is not null or feedable_type != 'Entourage'")
      end

      # actions are filtered out based on update date
      feeds = feeds.where('group_type not in (?) or feeds.updated_at >= ?', [:action], time_range.hours.ago)

      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)
      feeds = feeds.where("(#{bounding_box_sql}) OR online = true")

      feeds = order_by_distance(feeds: feeds)
      feeds = feeds.page(page).per(per)

      feeds = feeds.preload(feedable: {user: :partner})

      feeds = feeds.sort_by(&:created_at).reverse
      # Note: feeds is now an Array.

      # detect if this was the last page (less items than requested)
      if feeds.count < per
        @last_page = true
      end

      feeds = insert_announcements(feeds: feeds) if announcements == :v1

      preload_user_join_requests(feeds)
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

      if page == 1
        @metadata[:unread_count] = UserServices::UnreadMessages.new(user: user).number_of_unread_messages
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

    private
    attr_reader :user, :page, :before, :latitude, :longitude, :types, :show_past_events, :partners_only, :time_range, :distance, :announcements, :cursor, :area, :page_token, :legacy_pagination

    def self.per
      ITEMS_PER_PAGE
    end
    def per; self.class.per; end

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          distance,
                                          units: :km)
    end

    def formated_types(types)
      FeedServices::Types.formated_for_user(types: types, user: user)
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

      # @metadata.merge!(announcements_metadata)

      feeds
    end

    def order_by_distance(feeds:)
      distance_from_center = PostgisHelper.distance_from(latitude, longitude)

      feeds
        .order(Arel.sql('case when online then 1 else 2 end'))
        .order(Arel.sql(distance_from_center))
        .order(created_at: :desc)
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
      clause = ['(joinable_type = ? and joinable_id in (?))']
      user_join_requests = user.join_requests
        .where((clause * feedable_ids.count).join(' OR '), *feedable_ids.flatten)
      user_join_requests =
        Hash[user_join_requests.map { |r| [[r.joinable_type, r.joinable_id], r] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.current_join_request =
          user_join_requests[[feed.feedable_type, feed.feedable_id]]
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
end
