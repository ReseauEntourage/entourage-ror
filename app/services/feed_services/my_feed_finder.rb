module FeedServices
  class MyFeedFinder

    DEFAULT_PER=25

    def initialize(user:, page:, per:, unread_only: false)
      @user = user
      @page = page.presence&.to_i || 1
      @per = per.presence&.to_i || DEFAULT_PER
      @unread_only = unread_only
      @metadata = {}
    end

    def self.user_feeds user:, unread_only:, entourages_only:
      return Feed.none if user.anonymous?

      if entourages_only
        feeds = user.community.entourages
      else
        feeds = user.community.feeds
      end

      if entourages_only
        k = "entourages"
      else
        k = "feeds"
      end
      feeds = feeds.where.not(status: :blacklisted)
      feeds = feeds.where("#{k}.status != 'suspended' OR #{k}.user_id = ?", user.id)

      feeds = feeds.joins(:join_requests)
      join_status =
        if unread_only
          [:accepted]
        else
          [:accepted, :pending]
        end
      feeds = feeds.where(
        join_requests: {
          user_id: user.id,
          status: join_status
        }
      )

      if unread_only
        clauses = ["(feed_updated_at is not null and (last_message_read < feed_updated_at or last_message_read is null))"]

        entourage_ids_for_pending_join_requests =
          JoinRequest
          .where(status: :pending)
          .joins(:entourage).merge(user.entourages.findable)
          .pluck("distinct joinable_id")

        if entourage_ids_for_pending_join_requests.any?
          if entourages_only
            l = "entourages.id"
          else
            l = "feedable_id"
          end
          clauses << "#{l} in (%s)" % entourage_ids_for_pending_join_requests.join(',')
        end

        feeds = feeds.where(clauses.join(" or "))
      end

      feeds
    end

    def self.unread_count user:
      entourages_only = true
      user_feeds(user: user, unread_only: true, entourages_only: entourages_only)
        .limit(99) # for performance in extreme cases
        .count("distinct entourages.id")
    end

    def feeds
      entourages_only = !user.pro? || @unread_only

      feeds = self.class.user_feeds user: user, unread_only: @unread_only, entourages_only: entourages_only

      if @page == 1
        @metadata[:unread_count] = UserServices::UnreadMessages.new(user: user).number_of_unread_messages
      end

      if feeds.none?
        return FeedWithCursor.new(feeds, cursor: nil, next_page_token: nil, metadata: @metadata)
      end

      feeds = feeds.order(updated_at: :desc) # TODO: account for feed_updated_at?
      feeds = feeds.page(page).per(per) # TODO: cursor would be better

      if entourages_only
        feeds = feeds.preload(user: :partner)
      else
        feeds = feeds.preload(feedable: {user: :partner})
      end

      if entourages_only
        feeds = feeds.map { |entourage| Announcement::Feed.new(entourage) }
      end

      feeds = feeds.to_a # feeds is now an Array.
      preload_user_join_requests(feeds)
      preload_entourage_moderations(feeds)
      unless entourages_only
        preload_tour_user_organizations(feeds)
      end
      preload_chat_messages_counts(feeds)
      preload_last_chat_messages(feeds)
      preload_last_join_requests(feeds)

      FeedWithCursor.new(
        feeds,
        cursor: nil,
        next_page_token: nil,
        metadata: @metadata
      )
    end

    private
    attr_reader :user, :page, :per

    def preload_user_join_requests(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(joinable_type = ? and joinable_id in (?))"]
      user_join_requests = user.join_requests
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      user_join_requests =
        Hash[user_join_requests.map { |r| [[r.joinable_type, r.joinable_id], r] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.current_join_request =
          user_join_requests[[feed.feedable_type, feed.feedable_id]]
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

    def preload_chat_messages_counts(feeds)
      user_join_request_ids = feeds.map { |feed| feed.try(:current_join_request)&.id }
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

    def preload_last_chat_messages(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        join_request_status = feed.try(:current_join_request)&.status
        next unless join_request_status == 'accepted'
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(messageable_type = ? and messageable_id in (?))"]
      last_chat_messages = ChatMessage
        .select("distinct on (messageable_type, messageable_id) messageable_type, messageable_id")
        .order("messageable_type, messageable_id, created_at desc")
        .select(:id, :content, :user_id, :created_at)
        .includes(:user)
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      last_chat_messages =
        Hash[last_chat_messages.map { |m| [[m.messageable_type, m.messageable_id], m] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.last_chat_message =
          last_chat_messages[[feed.feedable_type, feed.feedable_id]]
      end
    end

    def preload_last_join_requests(feeds)
      feedable_ids = {}
      feeds.each do |feed|
        join_request_status = feed.try(:current_join_request)&.status
        next unless join_request_status == 'accepted'
        (feedable_ids[feed.feedable_type] ||= []).push feed.feedable_id
      end
      feedable_ids.delete 'Announcement'
      return if feedable_ids.empty?
      clause = ["(joinable_type = ? and joinable_id in (?))"]
      last_join_requests = JoinRequest
        .select("distinct on (joinable_type, joinable_id) joinable_type, joinable_id")
        .order("joinable_type, joinable_id, created_at desc")
        .select(:id, :status, :user_id, :created_at)
        .where(status: :pending)
        .where((clause * feedable_ids.count).join(" OR "), *feedable_ids.flatten)
      last_join_requests =
        Hash[last_join_requests.map { |r| [[r.joinable_type, r.joinable_id], r] }]
      feeds.each do |feed|
        next if feed.feedable.is_a?(Announcement)
        feed.last_join_request =
          last_join_requests[[feed.feedable_type, feed.feedable_id]]
      end
    end
  end
end
