module V1
  class LegacyFeedSerializer
    def initialize(feeds:, user:, include_last_message: false, base_url: nil, key_infos: nil)
      @feeds = feeds.entries
      @cursor = feeds.cursor
      @next_page_token = feeds.next_page_token
      @metadata = feeds.metadata

      @user = user
      @include_last_message = include_last_message
      @base_url = base_url
      @key_infos = key_infos || {}
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

      # the iOS app used to reorder the feed by updated_at
      if key_infos[:device] == 'iOS' && !cursor.nil?
        result.each.with_index do |f, i|
          f[:data]['updated_at'] = Time.at(100 + result.count - i).as_json
        end
      end

      if !cursor.nil? && result.any?
        # the apps use the last items's updated_at as cursor
        result.last[:data]['updated_at'] = cursor
      end

      payload = {feeds: result}

      if @next_page_token != nil
        payload[:next_page_token] = @next_page_token
      end

      if @metadata[:unread_count] != nil
        payload[:unread_count] = @metadata[:unread_count]
      end

      return payload
    end

    private
    attr_reader :feeds, :user, :include_last_message, :base_url, :key_infos, :cursor

    def preloaded_attributes(feed)
      {
        current_join_request: feed.current_join_request,
        number_of_unread_messages: feed.number_of_unread_messages,
        last_chat_message: feed.last_chat_message,
        last_join_request: feed.last_join_request
      }
    end
  end
end
