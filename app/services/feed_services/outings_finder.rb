require 'geocoder/sql'

module FeedServices
  class OutingsFinder
    include FeedServices::Preloader

    LIMIT = 25
    RADIUS = [10, units: :km]

    def initialize(user:,
                   latitude:,
                   longitude:,
                   starting_after: nil)
      @user = user
      @latitude = latitude
      @longitude = longitude
      @starting_after = starting_after
    end

    def feeds
      outings = user.community.entourages
        .where(group_type: :outing, status: :open)

      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

      feeds = outings
        .where("(#{bounding_box_sql}) OR online = true")
        .where("metadata->>'ends_at' >= ?", Time.zone.now)
        .order(Arel.sql("metadata->>'starts_at' asc, id"))
        .limit(LIMIT)
        .includes(user: :partner)

      if starting_after != nil
        last_of_previous_page = outings.find_by!(uuid_v2: starting_after)
        feeds = feeds.where(
          "ARRAY[metadata->>'starts_at', id::text] > ARRAY[?, ?::text]",
          last_of_previous_page.metadata[:starts_at], last_of_previous_page.id
        )
      end

      feeds = feeds.map { |outing| Announcement::Feed.new(outing) }

      preload_user_join_requests(feeds)
      preload_chat_messages_counts(feeds)

      feeds
    end

    private
    attr_reader :user, :latitude, :longitude, :starting_after

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], *RADIUS)
    end

    def preload_user_join_requests(feeds)
      feedable_ids = feeds.map(&:feedable_id)
      return if feedable_ids.empty?
      user_join_requests = user.join_requests
        .where(joinable_type: :Entourage, joinable_id: feedable_ids)
      user_join_requests =
        Hash[user_join_requests.map { |r| [r.joinable_id, r] }]
      feeds.each do |feed|
        feed.current_join_request =
          user_join_requests[feed.feedable_id]
      end
    end
  end
end
