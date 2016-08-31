module V1
  class FeedSerializer
    def initialize(feeds:, user:)
      @feeds = feeds
      @user = user
    end

    def to_json
      result = feeds.map do |feed|
        if feedable.is_a?(Tour)
          {
              type: "Tour",
              data: JSON.parse(V1::TourSerializer.new(feed.feedable, {scope: user, root: false}).to_json),
              heatmap_size: 20
          }
        elsif feed.is_a?(Entourage)
          {
              type: "Entourage",
              data: JSON.parse(V1::EntourageSerializer.new(feed.feedable, {scope: user, root: false}).to_json),
              heatmap_size: 20
          }
        end
      end
      return {"feeds": result}
    end

    private
    attr_reader :feeds, :user
  end
end