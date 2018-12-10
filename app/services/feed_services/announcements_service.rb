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

      announcements.each do |announcement|
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
        id: 14,
        title: "Don de Chaleur Humaine",
        body: "Aidez-nous à réchauffer le cœur des sans-abri en cette période particulière des fêtes de Noël",
        image_url: true,
        action: "Je fais un don",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 2
      )

      announcements.push Announcement.new(
        id: 15,
        title: "Opé calendrier de l'avent inversé",
        body: "L’idée ? Chaque jour du mois de Décembre, mettez un petit cadeau dans une boîte que vous irez offrir à un voisin démuni le jour de Noël",
        image_url: false,
        action: "Je me lance",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 6
      )

      announcements.push Announcement.new(
        id: 13,
        title: "Entourage recrute ses ambassadeurs",
        body: "Vous voulez vous engager pour rendre votre quartier plus humain avec les personnes SDF ? Devenez ambassadeur Entourage, une mission de bénévolat exaltante !",
        image_url: false,
        action: "Je postule",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 11
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
