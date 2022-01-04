module FeedServices
  module Preloader
    def preload_chat_messages_counts(feeds)
      user_join_request_ids = feeds.map { |feed| feed.try(:current_join_request)&.id }
      return if user_join_request_ids.empty?
      counts = JoinRequest
        .with_unread_messages
        .where(id: user_join_request_ids)
        .group(:id)
        .count
      counts.default = 0
      feeds.each do |feed|
        join_request_id = feed.try(:current_join_request)&.id
        next if join_request_id.nil?
        feed.number_of_unread_messages = counts[join_request_id]
      end
    end
  end
end
