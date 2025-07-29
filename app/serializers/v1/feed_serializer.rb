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
        if feed.feedable.is_a?(Entourage)
          {
              type: 'Entourage',
              data: V1::EntourageSerializer.new(feed.feedable, {scope: {user: user, include_last_message: include_last_message}.merge(preloaded_attributes(feed)), root: false}).as_json,
              heatmap_size: 20
          }
        elsif feed.feedable.is_a?(Announcement)
          {
              type: 'Announcement',
              data: V1::AnnouncementSerializer.new(feed.feedable, scope: { user: user, base_url: base_url }, root: false).as_json,
          }
        else
          {
              type: 'Unknown',
              data: {}.as_json,
          }
        end
      end

      return {"feeds": result}
    end

    private
    attr_reader :feeds, :user, :include_last_message, :base_url, :key_infos, :cursor

    def preloaded_attributes(feed)
      {
        current_join_request: feed.current_join_request,
        number_of_unread_messages: feed.number_of_unread_messages
      }
    end
  end
end
