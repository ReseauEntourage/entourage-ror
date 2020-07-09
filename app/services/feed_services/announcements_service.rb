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

      areas = user.departement_slugs
      if areas.any?
        areas &= ModerationArea.all_slugs
        areas = [:hors_zone] if areas.none?
      else
        areas = [:sans_zone]
      end

      user_goal = user.goal || :goal_not_known

      announcements = Announcement.active.for_areas(areas).for_user_goal(user_goal)
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
