module FeedServices
  class AnnouncementsService
    def initialize(feeds:, user:, offset:, area:, last_page: false)
      @feeds = feeds
      @user = user
      @offset = offset.try(:to_i) || 0
      @area = area
      @last_page = last_page
      @metadata = {}
    end

    attr_reader :user, :offset, :area, :last_page

    def feeds
      announcements = select_announcements

      return [@feeds, @metadata] if announcements.empty?

      feeds = @feeds.to_a

      announcements.sort_by(&:position).each do |announcement|
        position = announcement.position - 1
        if position < offset
          @offset += 1
        elsif position - offset < feeds.length
          feeds.insert(position - offset, announcement.feed_object)
        elsif last_page
          feeds.push(announcement.feed_object)
        else
          break
        end
      end

      [feeds, @metadata]
    end

    private

    def select_announcements
      return [] unless user.community == :entourage

      dep = nil
      if user.address&.country == 'FR'
        dep = user.address.postal_code.to_s.first(2)
      end

      announcements = Announcement.active

      unless dep.in?(['75', '93', '92'])
        announcements = announcements.where.not(id: [103, 104])
      end

      announcements = announcements.ordered.to_a

      # 3   9  15  22  29  36  ...
      #  +6  +6  +7  +7  +7  ...
      position = 3
      announcements.each do |a|
        a.position = position
        if position < 15
          position += 6
        else
          position += 7
        end
      end

      announcements
    end
  end
end
