module FeedServices
  class AnnouncementsService
    def initialize(feeds:, user:, page:, area:)
      @feeds = feeds
      @user = user
      @page = page.try(:to_i) || 1
      @area = area
      @metadata = {}
    end

    attr_reader :user, :page, :area

    def feeds
      return [@feeds, @metadata] if page != 1

      announcements = select_announcements

      return [@feeds, @metadata] if announcements.empty?

      feeds = @feeds.to_a

      announcements.sort_by(&:position).each do |announcement|
        position = [feeds.length, announcement.position].min
        feeds.insert(position, announcement.feed_object)
      end

      [feeds, @metadata]
    end

    private

    def select_announcements
      announcements = []

      return announcements unless user.community == :entourage

      announcements.push Announcement.new(
        id: 17,
        title: "3,2,1 ... Bonne année 🎉",
        body: "Toute l'équipe Entourage vous souhaite une bonne année 2019 ! Que celle-ci vous remplisse de joix et de bonheur 👌 Ensemble répandons la chaleur humaine dans nos rues 👫",
        image_url: true,
        action: "#chaleurhumaine",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 2
      )

      announcements.push Announcement.new(
        id: 18,
        title: "Bonne résolution #1",
        body: "Et si on commencait 2019, en s'intéressant au monde de la rue pour le comprendre ? Découvrez notre guide pédagogique \"Simple comme Bonjour\" pour créer du lien avec vos voisins sans-abri et avoir des conseils concrets !",
        image_url: true,
        action: "Voir la vidéo",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 8
      )

      announcements.push Announcement.new(
        id: 13,
        title: "Entourage recrute ses ambassadeurs",
        body: "Devenez ambassadeur Entourage, une mission de bénévolat exaltante ! Pour s'engager et rendre votre quartier plus humain avec les personnes SDF.",
        image_url: true,
        action: "Je postule",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 14
      )

      announcements
    end

    def with_first_name text
      if first_name.present?
        "#{first_name}, #{text}"
      else
        text.capitalize
      end
    end

    def first_name
      @first_name ||=
        (user.first_name || "")
        .scan(/[[:alpha:]]+|[^[:alpha:]]+/)
        .map(&:capitalize)
        .join
        .strip
        .presence
    end
  end
end
