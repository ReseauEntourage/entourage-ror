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
    end

    def feeds
      feeds = Feed.where.not(status: 'blacklisted')
                  .includes(feedable: [:user, :join_requests])
      feeds = feeds.where(feedable_type: "Entourage") unless (show_tours=="true" && user.pro?)
      feeds = feeds.where(feed_type: feed_type) if feed_type
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
      elsif before
        feeds.before(DateTime.parse(before)).limit(25)
      else
        feeds.limit(25)
      end

      UserServices::NewsfeedHistory.save(user: user,
                                         latitude: latitude,
                                         longitude: longitude)

      feeds =
        feeds.group("feeds.feedable_type, feeds.feed_type, feeds.user_id, feeds.title, feeds.status, feeds.feedable_id, feeds.latitude, feeds.longitude, feeds.number_of_people, feeds.created_at, feeds.updated_at")
             .order("updated_at DESC")

      feeds = insert_announcements(feeds: feeds) if announcements == :v1

      feeds
    end

    private
    attr_reader :user, :page, :per, :before, :latitude, :longitude, :show_tours, :feed_type, :show_my_entourages_only, :show_my_tours_only, :show_my_partner_only, :time_range, :tour_status, :entourage_status, :author, :invitee, :distance, :announcements

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
  end
end
