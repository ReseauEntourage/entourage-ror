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
                   types: nil,
                   latitude:,
                   longitude:,
                   show_my_entourages_only: "false",
                   show_my_tours_only: "false",
                   show_my_partner_only: "false",
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
      @before = before
      @latitude = latitude
      @longitude = longitude
      @show_tours = show_tours
      @feed_type = join_types(entourage_types: entourage_types, tour_types: tour_types)
      @types = formated_types(types) if types != nil
      @show_my_entourages_only = show_my_entourages_only=="true"
      @show_my_tours_only = show_my_tours_only=="true"
      @show_my_partner_only = show_my_partner_only=="true"
      @time_range = time_range.to_i
      @tour_status = formated_status(tour_status)
      @entourage_status = formated_status(entourage_status)
      @author = author
      @invitee = invitee
      @distance = [(distance&.to_i || DEFAULT_DISTANCE), 40].min
      @announcements = announcements.try(:to_sym)
      @cursor = nil
      @version = FeatureSwitch.new(user).variant(:feed)
      @area = FeedRequestArea.new(@latitude, @longitude)
      @metadata = {}

      @time_range = lyon_grenoble_timerange_workaround
    end

    def feeds
      feeds = Feed.where.not(status: 'blacklisted')
                  .includes(feedable: [{ user: { default_user_partners: :partner} }, :join_requests])

      if types != nil
        feeds = feeds.where(feed_category: types)
      else
        feeds = feeds.where(feedable_type: "Entourage") unless (show_tours=="true" && user.pro?)
        feeds = feeds.where(feed_type: feed_type) if feed_type
      end
      feeds = filter_my_feeds_only(feeds: feeds)
      feeds = filter_my_partner_only(feeds: feeds) if show_my_partner_only
      feeds = feeds.where(user: author) if author
      feeds = feeds.where("feeds.created_at > ?", time_range.hours.ago)
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
      elsif version == :v2 && latitude && longitude && before
        # extract cursor from `before` parameter
        date = DateTime.parse(before)
        @cursor = date.to_i if date.year == 1970
        feeds # pagination is handled later for clarity
      elsif before
        feeds.before(DateTime.parse(before)).limit(25)
      else
        feeds.limit(25)
      end

      UserServices::NewsfeedHistory.save(user: user,
                                         latitude: latitude,
                                         longitude: longitude)

      feeds =
        if version == :v2 && latitude && longitude
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

      if version == :v2
        cursor = Time.at(cursor + 1).as_json if !cursor.nil?
        FeedWithCursor.new(feeds, cursor: cursor, metadata: @metadata)
      else
        feeds
      end
    end

    private
    attr_reader :user, :page, :per, :before, :latitude, :longitude, :show_tours, :feed_type, :types, :show_my_entourages_only, :show_my_tours_only, :show_my_partner_only, :time_range, :tour_status, :entourage_status, :author, :invitee, :distance, :announcements, :cursor, :area, :version

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

    PRO_TYPES = {
      'tm' => 'tour_medical',
      'tb' => 'tour_barehands',
      'ta' => 'tour_alimentary',

      # fix wrong key in iOS 4.1 - 4.3
      'ts' => 'tour_barehands',
    }

    COMMON_TYPES = {
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
    }

    def formated_types(types)
      allowed_types = COMMON_TYPES
      allowed_types.merge!(PRO_TYPES) if user.pro?

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


      if area.in?(['Lyon', 'Grenoble'])
        720 # 30 days
      else
        time_range
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
      { name: 'République', lat: 48.8676, lng: 2.3639, radius: 1.5, coeff: 0.65780 },
      { name: 'Paris',      lat: 48.8558, lng: 2.3369, radius: 7.0, coeff: 0.65796 },
      { name: 'Lyon',       lat: 45.7544, lng: 4.8445, radius: 6.0, coeff: 0.69774 },
      { name: 'Grenoble',   lat: 45.1864, lng: 5.7237, radius: 6.0, coeff: 0.70480 },
      { name: 'Lille',      lat: 50.6284, lng: 3.0389, radius: 6.0, coeff: 0.63435 },
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
        area = AREAS.find { |a| _distance(a[:lat], a[:lng], a[:coeff]) <= a[:radius] }
        area.nil? ? UNKNOWN_AREA : area[:name]
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
