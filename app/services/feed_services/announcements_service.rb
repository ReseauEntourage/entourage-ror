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

      announcements = select_announcements

      return @feeds if announcements.empty?

      feeds = @feeds.to_a

      return @feeds if feeds.empty?

      announcements.each do |announcement|
        position = [feeds.length, announcement.position].min
        feeds.insert(position, announcement.feed_object)
      end

      feeds
    end

    private

    def select_announcements
      announcements = []

      announcements.push Announcement.new(
        id: 2,
        title: "Une autre façon de contribuer !",
        body: "Entourage a besoin de votre soutien pour continuer sa mission.",
        action: "Aider",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 5
      )

      # first_name = (user.first_name || "").scan(/[[:alpha:]]+|[^[:alpha:]]+/).map(&:capitalize).join.strip

      # if first_name.present?
      #   title = "#{first_name}, ne manquez rien !"
      # else
      #   title = "ne manquez rien !"
      # end

      # announcements.push Announcement.new(
      #   id: 3,
      #   title: title,
      #   body: "Définissez votre zone d’action pour être informé des nouveautés du quartier.",
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true,
      #   position: 5
      # )

      announcements.push Announcement.new(
        id: 4,
        title: "En 2018, osez la rencontre !",
        body: "Découvrez des conseils concrets pour aller vers les personnes sans-abri.",
        action: "Voir",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 1
      )

      announcements
    end
  end
end
