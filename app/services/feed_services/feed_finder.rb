module FeedServices
  class FeedFinder
    def initialize(user:,
                   page:,
                   per:,
                   show_tours:,
                   entourage_types:,
                   tour_types:,
                   show_my_entourages_only: "false",
                   show_my_tours_only: "false",
                   time_range: 24,
                   tour_status:,
                   entourage_status:,
                   before: nil,
                   author: nil,
                   invitee: nil)
      @user = user
      @page = page
      @per = per
      @before = before
      @show_tours = show_tours
      @feed_type = join_types(entourage_types: entourage_types, tour_types: tour_types)
      @show_my_entourages_only = show_my_entourages_only=="true"
      @show_my_tours_only = show_my_tours_only=="true"
      @time_range = (time_range || 24).to_i
      @tour_status = [tour_status].flatten
      @entourage_status = [entourage_status].flatten
      @author = author
      @invitee = invitee
    end

    def feeds
      feeds = Feed
      feeds = feeds.where(feedable_type: "Entourage") unless (show_tours=="true" && user.pro?)
      feeds = feeds.where(feed_type: feed_type) if feed_type
      feeds = feeds.where("(feedable_type='Entourage' AND feeds.status IN (?)) OR (feedable_type='Tour' AND feeds.status IN (?))", entourage_status, tour_status)
      feeds = feeds.where(user: author) if author
      feeds = feeds.where("feeds.created_at > ?", time_range.hours.ago)

      if show_my_entourages_only && show_my_tours_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id) OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id) AND join_requests.status='accepted')")
      elsif show_my_entourages_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.status='accepted') OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id))")
      elsif show_my_tours_only
        feeds = feeds.joins("INNER JOIN join_requests ON ((join_requests.joinable_type='Entourage' AND feeds.feedable_type='Entourage' AND join_requests.joinable_id=feeds.feedable_id) OR (join_requests.joinable_type='Tour' AND feeds.feedable_type='Tour' AND join_requests.joinable_id=feeds.feedable_id AND join_requests.status='accepted'))")
      end

      if invitee
        feeds = feeds.joins("INNER JOIN entourage_invitations ON ((entourage_invitations.invitable_type='Entourage' AND feeds.feedable_type='Entourage' AND entourage_invitations.invitable_id=feeds.feedable_id AND entourage_invitations.status='accepted') OR (entourage_invitations.invitable_type='Tour' AND feeds.feedable_type='Tour' AND entourage_invitations.invitable_id=feeds.feedable_id  AND entourage_invitations.status='accepted')  AND entourage_invitations.invitee_id=#{invitee.id})")
      end

      feeds = if page || per
        feeds.page(page).per(per)
      elsif before
        feeds.before(DateTime.parse(before)).limit(25)
      else
        feeds.limit(25)
      end

      feeds.order("updated_at DESC")
    end

    private
    attr_reader :user, :page, :per, :before, :show_tours, :feed_type, :show_my_entourages_only, :show_my_tours_only, :time_range, :tour_status, :entourage_status, :author, :invitee

    def join_types(entourage_types:, tour_types:)
      entourage_types = formated_type(entourage_types) || Entourage::ENTOURAGE_TYPES
      tour_types = formated_type(tour_types) || Tour::TOUR_TYPES
      entourage_types + tour_types
    end

    def formated_type(types)
      types&.gsub(" ", "")&.split(",")
    end
  end
end