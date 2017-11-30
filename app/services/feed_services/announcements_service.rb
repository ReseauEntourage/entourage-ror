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
      return
      Announcement.new(
        id: 1,
        title: "Et si on comprenait le monde de la rue ?",
        body: "Préjugés sur les personnes sans-abri : 3 minutes pour changer son regard !",
        action: "Voir",
        author: User.find_by(email: "guillaume@entourage.social"),
      )
    end
  end
end
