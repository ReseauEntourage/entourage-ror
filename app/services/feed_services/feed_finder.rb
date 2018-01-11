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

      feeds = insert_announcements(feeds: feeds) if announcements == :v1

      feeds
    end

    private
    attr_reader :user, :page, :per, :before, :latitude, :longitude, :show_tours, :feed_type, :types, :show_my_entourages_only, :show_my_tours_only, :show_my_partner_only, :time_range, :tour_status, :entourage_status, :author, :invitee, :distance, :announcements, :cursor, :version

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
    }

    COMMON_TYPES = {
      'as' => 'ask_for_help_social',
      'ae' => 'ask_for_help_event',
      'am' => 'ask_for_help_mat_help',
      'ar' => 'ask_for_help_resource',
      'ai' => 'ask_for_help_info',
      'aa' => 'ask_for_help_skill',
      'ao' => 'ask_for_help_other',

      'cs' => 'contribution_social',
      'ce' => 'contribution_event',
      'cm' => 'contribution_mat_help',
      'cr' => 'contribution_resource',
      'ci' => 'contribution_info',
      'ca' => 'contribution_skill',
      'co' => 'contribution_other',
    }

    def formated_types(types)
      allowed_types = COMMON_TYPES
      allowed_types.merge!(PRO_TYPES) if user.pro?

      types = (types || "").split(',').map(&:strip)
      types = types.map { |t| allowed_types[t] || t }

      types & allowed_types.values
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
      AnnouncementsService.new(
        feeds: feeds,
        user: user,
        page: page
      ).feeds
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

      FeedWithCursor.new(feeds, cursor: Time.at(cursor + 1).as_json)
    end

    def lyon_grenoble_timerange_workaround
      return time_range if time_range != 192 # only workaround the '8 days' setting
      return time_range if latitude.nil? || longitude.nil?

      lat = latitude.to_f
      lng = longitude.to_f
      cities = [
        { name: 'Lyon',     lats: 45.71..45.80, lngs: 4.77..4.91 },
        { name: 'Grenoble', lats: 45.15..45.22, lngs: 5.67..5.79 },
      ]

      cities.each do |c|
        p [c[:name], lat, lat.in?(c[:lats]), lng, lng.in?(c[:lngs])]
      end

      if cities.any? { |c| lat.in?(c[:lats]) && lng.in?(c[:lngs]) }
        720 # 30 days
      else
        time_range
      end
    end
  end

  class FeedWithCursor < SimpleDelegator
    def initialize array, cursor:
      @cursor = cursor.to_s
      super array.to_ary
    end

    # prevent accidental conversion back to array
    def to_a
      self
    end

    attr_reader :cursor
  end
end
