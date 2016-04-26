module V1
  class FeedSerializer
    def initialize(feeds:, user:)
      @feeds = feeds
      @user = user
    end

    def to_json
      result = feeds.map do |feed|
        if feed.is_a?(Tour)
          {
              type: "Tour",
              data: JSON.parse(TourSerializer.new(feed, {scope: user, root: false}).to_json)
          }
        elsif feed.is_a?(Entourage)
          {
              type: "Entourage",
              data: JSON.parse(EntourageSerializer.new(feed, {scope: user, root: false}).to_json)
          }
        end
      end
      return {"feeds": result}
    end

    private
    attr_reader :feeds, :user
  end
end