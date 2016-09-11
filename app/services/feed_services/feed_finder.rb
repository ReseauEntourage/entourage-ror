module FeedServices
  class FeedFinder
    def initialize(user:,
                   page:,
                   per:,
                   before: nil,
                   show_tours:,
                   entourage_types:,
                   tour_types:)
      @user = user
      @page = page
      @per = per
      @before = before
      @show_tours = show_tours
      @feed_type = join_types(entourage_types: entourage_types, tour_types: tour_types)
    end

    def feeds
      feeds = Feed

      feeds = feeds.where(feedable_type: "Entourage") unless show_tours=="true"
      feeds = feeds.where(feed_type: feed_type) if feed_type

      if page || per
        feeds.page(page).per(per)
      elsif before
        feeds.before(DateTime.parse(before)).limit(25)
      else
        feeds.limit(25)
      end
      feeds.order("updated_at DESC")
    end

    private
    attr_reader :user, :page, :per, :before, :show_tours, :feed_type

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