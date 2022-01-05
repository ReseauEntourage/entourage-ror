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

    def preload_tour_user_organizations(feeds)
      organization_ids = feeds.find_all { |feed| feed.feedable.is_a?(Tour) }.map { |feed| feed.feedable.user&.organization_id }.compact.uniq
      return if organization_ids.empty?
      organizations = Organization.where(id: organization_ids)
      organizations = Hash[organizations.map { |o| [o.id, o] }]
      feeds.each do |feed|
        next unless feed.feedable.is_a?(Tour)
        next if feed.feedable.user.nil?
        feed.feedable.user.organization = organizations[feed.feedable.user.organization_id]
      end
    end

    def preload_entourage_moderations(feeds)
      entourage_ids = feeds.find_all { |feed| feed.feedable.is_a?(Entourage) && feed.feedable.has_outcome? }.map(&:feedable_id)
      return if entourage_ids.empty?
      entourage_moderations = EntourageModeration.where(entourage_id: entourage_ids)
      entourage_moderations = Hash[entourage_moderations.map { |m| [m.entourage_id, m] }]
      feeds.each do |feed|
        next unless feed.feedable.is_a?(Entourage) && feed.feedable.has_outcome?
        feed.feedable.association(:moderation).target = entourage_moderations[feed.feedable_id]
      end
    end
  end
end
