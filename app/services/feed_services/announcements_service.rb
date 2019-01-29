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
        if announcement.position <= offset
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

      announcements.push Announcement.new(
        id: 19,
        title: "❄️❄️ Grrrr ❄️❄️",
        body: "Le grand froid est arrivé ! Comment faire pour aider les personnes sans-abri à son échelle ? Pas d'inquiétude on vous explique. 👌",
        image_url: true,
        action: "En savoir plus",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 2
      )

      announcements.push Announcement.new(
        id: 20,
        title: "Bonne résolution #2",
        body: "Comprendre la rue passe aussi par écouter les témoignages de ceux qui l'ont vécu. Cette semaine, parole aux femmes SDF 👩🏽.",
        image_url: true,
        action: "Voir la vidéo",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 8
      )

      announcements.push Announcement.new(
        id: 10,
        title: "Besoin d’aide pour agir ? Contactez Guillaume",
        body: "Une question, une information ? Le modérateur de l’équipe est la pour répondre à toutes vos demandes !",
        image_url: true,
        action: "Je contacte",
        url: "mailto:guillaume@entourage.social",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false,
        position: 14
      )

      announcements.push Announcement.new(
        id: 13,
        title: "Entourage recrute ses ambassadeurs",
        body: "Devenez ambassadeur Entourage, une mission de bénévolat exaltante ! Pour s'engager et rendre votre quartier plus humain avec les personnes SDF.",
        image_url: true,
        action: "Je postule",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 24
      )

      announcements.push Announcement.new(
        id: 21,
        title: "Les fêtes de Noël Entourage en photos",
        body: "Les \"Talents de la rue\" sont montés sur scène pour le réveillon, et ça valait le détour.",
        image_url: true,
        action: "Je regarde",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true,
        position: 34
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
