module FeedServices
  class AnnouncementsService
    def initialize(feeds:, user:, page:)
      @feeds = feeds
      @user = user
      @page = page.try(:to_i) || 1
    end

    attr_reader :user, :page

    def feeds
      return @feeds if page != 1

      announcement = select_announcement

      return @feeds if announcement.nil?

      feeds = @feeds.to_a
      position = [feeds.length, 1].min
      feeds.insert(position, announcement.feed_object)
    end

    private

    def select_announcement
      Announcement.new(
        id: 1,
        title: "Une autre façon de contribuer.",
        body: "#{user.first_name}, Entourage a besoin de vous pour continuer à accompagner les sans-abri.",
        action: "Aider",
        author: User.find_by(email: "claire@duizabo.fr")
      )
    end
  end
end
