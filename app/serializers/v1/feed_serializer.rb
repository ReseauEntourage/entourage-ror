module V1
  class FeedSerializer
    def initialize(feeds:, user:, include_last_message: false, base_url: nil)
      @feeds = feeds
      @user = user
      @include_last_message = include_last_message
      @base_url = base_url
    end

    def to_json
      result = feeds.map do |feed|
        if feed.feedable.is_a?(Tour)
          {
              type: "Tour",
              data: JSON.parse(V1::TourSerializer.new(feed.feedable, {scope: {user: user, include_last_message: include_last_message}, root: false}).to_json),
              heatmap_size: 20
          }
        elsif feed.feedable.is_a?(Entourage)
          {
              type: "Entourage",
              data: JSON.parse(V1::EntourageSerializer.new(feed.feedable, {scope: {user: user, include_last_message: include_last_message}, root: false}).to_json),
              heatmap_size: 20
          }
        elsif feed.feedable.is_a?(Announcement)
          {
              type: "Announcement",
              data: V1::AnnouncementSerializer.new(feed.feedable, scope: { user: user, base_url: base_url }, root: false).as_json,
          }
        end
      end
      return {"feeds": result}
    end

    private
    attr_reader :feeds, :user, :include_last_message, :base_url
  end
end