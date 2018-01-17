module V1
  class FeedSerializer
    def initialize(feeds:, user:, include_last_message: false, base_url: nil, key_infos: nil)
      @feed_version = FeatureSwitch.new(user).variant(:feed)

      if feed_version == :v2
        @feeds = feeds.entries
        @cursor = feeds.cursor
      else
        @feeds = feeds
      end

      @user = user
      @include_last_message = include_last_message
      @base_url = base_url
      @key_infos = key_infos || {}
    end

    def to_json
      result = feeds.map do |feed|
        if feed.feedable.is_a?(Tour)
          {
              type: "Tour",
              data: V1::TourSerializer.new(feed.feedable, {scope: {user: user, include_last_message: include_last_message}, root: false}).as_json,
              heatmap_size: 20
          }
        elsif feed.feedable.is_a?(Entourage)
          {
              type: "Entourage",
              data: V1::EntourageSerializer.new(feed.feedable, {scope: {user: user, include_last_message: include_last_message}, root: false}).as_json,
              heatmap_size: 20
          }
        elsif feed.feedable.is_a?(Announcement)
          {
              type: "Announcement",
              data: V1::AnnouncementSerializer.new(feed.feedable, scope: { user: user, base_url: base_url }, root: false).as_json,
          }
        end
      end

      # the iOS app reorders the feed by updated_at
      if key_infos[:device] == 'iOS'
        result.each.with_index do |f, i|
          f[:data]['updated_at'] = Time.at(100 + result.count - i).as_json
        end
      end

      if feed_version == :v2
        if !cursor.nil? && result.any?
          # the apps use the last items's updated_at as cursor
          result.last[:data]['updated_at'] = cursor
        end
      end

      return {"feeds": result}
    end

    private
    attr_reader :feeds, :user, :include_last_message, :base_url, :key_infos, :cursor, :feed_version
  end
end