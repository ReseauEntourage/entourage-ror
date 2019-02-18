module FeedServices
  class AnnouncementsService
    def initialize(feeds:, user:, offset:, area:)
      @feeds = feeds
      @user = user
      @offset = offset.try(:to_i) || 0
      @area = area
      @metadata = {}
    end

    attr_reader :user, :offset, :area

    def feeds
      announcements = select_announcements

      return [@feeds, @metadata] if announcements.empty?

      feeds = @feeds.to_a

      announcements.sort_by(&:position).each do |announcement|
        if announcement.position < offset
          @offset += 1
        elsif announcement.position > offset + feeds.length
          break
        else
          feeds.insert(announcement.position - offset, announcement.feed_object)
        end
      end

      [feeds, @metadata]
    end

    private

    def select_announcements
      announcements = []

      return announcements unless user.community == :entourage

      conversation_uuid = ConversationService.uuid_for_participants(
        [
          User.find_by(email: "guillaume@entourage.social").id,
          user.id
        ],
        validated: false
      )
      conversation_url = "#{ENV['DEEPLINK_SCHEME']}://entourage/#{conversation_uuid}"

      announcements.push Announcement.new(
        id: 10,
        title: "Besoin d’aide pour agir ? Contactez Guillaume",
        body: "Une question, une information ? Le modérateur de l’équipe est la pour répondre à toutes vos demandes !",
        image_url: true,
        action: "Je contacte",
        url: conversation_url,
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 2
      )

      announcements.push Announcement.new(
        id: 22,
        title: "Envie d'en savoir plus ?",
        body: %("Simple comme Bonjour" le guide pour aller à la rencontre des personnes sans-abri ! Décrouvrez les vidéos, les interviews, les témoignages et le guide),
        image_url: true,
        action: "Voir",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 8
      )

      announcements.push Announcement.new(
        id: 23,
        title: "Suivez-nous sur les réseaux !",
        body: "Retrouvez Entourage également sur tous vos réseaux sociaux ! Suivez toute nos actualités, photos, vidéos, belles histoires !",
        image_url: true,
        action: "Je rejoins",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 14
      )

      announcements.push Announcement.new(
        id: 24,
        title: "Entourage débarque sur votre ordinateur !",
        body: "Retrouvez dès maintenant l'application Entourage sur votre ordinateur, directement sur le site internet www.entourage.social/app !",
        image_url: true,
        action: "Voir",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 24
      )

      announcements.push Announcement.new(
        id: 13,
        title: "Entourage recrute ses ambassadeurs",
        body: "Devenez ambassadeur Entourage, une mission de bénévolat exaltante ! Pour s'engager et rendre votre quartier plus humain avec les personnes SDF.",
        image_url: true,
        action: "Je postule",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 34
      )

      announcements.push Announcement.new(
        id: 21,
        title: "Les fêtes de Noël Entourage en photos",
        body: "Les \"Talents de la rue\" sont montés sur scène pour le réveillon, et ça valait le détour.",
        image_url: true,
        action: "Je regarde",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 44
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
