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
        elsif position - offset <= feeds.length
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
      announcements = []

      return announcements unless user.community == :entourage

      # announcements.push  Announcement.new(
      #   id: 1,
      #   title: "Et si on comprenait le monde de la rue ?",
      #   body: "Préjugés sur les personnes sans-abri : 3 minutes pour changer son regard !",
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      # )

      # announcements.push Announcement.new(
      #   id: 2,
      #   title: "Une autre façon de contribuer !",
      #   body: "Entourage a besoin de votre soutien pour continuer sa mission.",
      #   action: "Aider",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: false
      # )

      # announcements.push Announcement.new(
      #   id: 3,
      #   title: with_first_name("ne manquez pas les actions autour de vous !"),
      #   body: "Définissez votre zone d'action pour être tenu(e) informé(e) des actions dans votre quartier.",
      #   action: "Définir ma zone",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 4,
      #   title: "En 2018, osez la rencontre !",
      #   body: "Découvrez des conseils concrets pour aller vers les personnes sans-abri.",
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # 5?

      # announcements.push Announcement.new(
      #   id: 6,
      #   title: "Le saviez-vous ? Chaque action est contrôlée.",
      #   body: "L'équipe de modération d'Entourage veille au respect des personnes et de la vie privée.",
      #   action: "En savoir plus",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 7,
      #   title: "Le top 5 des belles actions !",
      #   body: "Découvrez les initiatives solidaires qui ont abouti grâce au réseau",
      #   action: "Inspirez-vous",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 8,
      #   title: %(Le "Comité de la rue", qu'est-ce que c'est ?),
      #   body: "Saviez-vous qu'Entourage est co-construit avec des personnes SDF ? ",
      #   action: "En savoir plus",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 9,
      #   title: "Fête des Voisins 2018 : invitez vos voisins SDF !",
      #   body: "vendredi 25 mai 2018, invitons TOUS les voisins à partager un moment : parlez-en aux personnes sans-abri de votre quartier",
      #   action: "J'agis",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # conversation_uuid = ConversationService.uuid_for_participants(
      #   [
      #     User.find_by(email: "guillaume@entourage.social").id,
      #     user.id
      #   ],
      #   validated: false
      # )
      # conversation_url = "#{ENV['DEEPLINK_SCHEME']}://entourage/#{conversation_uuid}"

      # announcements.push Announcement.new(
      #   id: 10,
      #   title: "Besoin d’aide ? Contactez Guillaume",
      #   body: "Une question, une information ? Le modérateur de l’équipe est la pour répondre à toutes vos demandes !",
      #   image_url: true,
      #   action: "Je contacte",
      #   url: conversation_url,
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: false
      # )

      # announcements.push Announcement.new(
      #   id: 11,
      #   title: with_first_name("n'attendez plus pour agir !"),
      #   body: "Conseils, rencontres, idées d'action auprès des SDF... Passez à l'action en discutant avec vos voisins solidaires.",
      #   image_url: true,
      #   action: "J'agis",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 12,
      #   title: with_first_name("découvrez les belles histoires sur notre blog !"),
      #   body: "Aujourd’hui, on vous partage la belle histoire de Roya-Rose (riveraine) et de Michael (sans-abri) 👌",
      #   action: "Découvrir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 13,
      #   title: "Entourage recrute ses ambassadeurs",
      #   body: "Devenez ambassadeur Entourage, une mission de bénévolat exaltante ! Pour s'engager et rendre votre quartier plus humain avec les personnes SDF.",
      #   image_url: true,
      #   action: "Je postule",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 14,
      #   title: "Participez à l'élan de générosité",
      #   body: "Entourage a besoin de votre soutien pour réchauffer le cœur des sans-abri en cette fin d'année",
      #   image_url: true,
      #   action: "Je fais un don",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: false
      # )

      # announcements.push Announcement.new(
      #   id: 15,
      #   title: "Opé calendrier de l'avent inversé",
      #   body: "L’idée ? Chaque jour du mois de Décembre, mettez un petit cadeau dans une boîte que vous irez offrir à un voisin démuni le jour de Noël",
      #   image_url: false,
      #   action: "Je me lance",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 16,
      #   title: "Où passer un réveillon solidaire ?",
      #   body: "On a répertorié pour vous les initiatives qui ont besoin de vous, auprès des personnes SDF",
      #   image_url: true,
      #   action: "Découvrir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 17,
      #   title: "3,2,1 ... Bonne année 🎉",
      #   body: "Toute l'équipe Entourage vous souhaite une bonne année 2019 ! Que celle-ci vous remplisse de joie et de bonheur 👌 Ensemble répandons la chaleur humaine dans nos rues 👫",
      #   image_url: true,
      #   action: "#chaleurhumaine",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 18,
      #   title: "Bonne résolution #1",
      #   body: "Et si on commencait 2019, en s'intéressant au monde de la rue pour le comprendre ? Découvrez notre guide pédagogique \"Simple comme Bonjour\" pour créer du lien avec vos voisins sans-abri et avoir des conseils concrets !",
      #   image_url: true,
      #   action: "Voir la vidéo",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 19,
      #   title: "❄️❄️ Grrrr ❄️❄️",
      #   body: "Le grand froid est arrivé ! Comment faire pour aider les personnes sans-abri à son échelle ? Pas d'inquiétude on vous explique. 👌",
      #   image_url: true,
      #   action: "En savoir plus",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 20,
      #   title: "Bonne résolution #2",
      #   body: "Comprendre la rue passe aussi par écouter les témoignages de ceux qui l'ont vécu. Cette semaine, parole aux femmes SDF 👩🏽.",
      #   image_url: true,
      #   action: "Voir la vidéo",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 21,
      #   title: "Les fêtes de Noël Entourage en photos",
      #   body: "Les \"Talents de la rue\" sont montés sur scène pour le réveillon, et ça valait le détour.",
      #   image_url: true,
      #   action: "Je regarde",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 22,
      #   title: "Envie d'en savoir plus ?",
      #   body: %("Simple comme Bonjour" le guide pour aller à la rencontre des personnes sans-abri ! Décrouvrez les vidéos, les interviews, les témoignages et le guide),
      #   image_url: true,
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 23,
      #   title: "Suivez-nous sur les réseaux !",
      #   body: "Retrouvez Entourage également sur tous vos réseaux sociaux ! Suivez toute nos actualités, photos, vidéos, belles histoires !",
      #   image_url: true,
      #   action: "Je rejoins",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: false
      # )

      # announcements.push Announcement.new(
      #   id: 24,
      #   title: "Entourage débarque sur votre ordinateur !",
      #   body: "Retrouvez dès maintenant l'application Entourage sur votre ordinateur, directement sur le site internet www.entourage.social/app !",
      #   image_url: true,
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: false
      # )

      # announcements.push Announcement.new(
      #   id: 25,
      #   title: "Comprendre Entourage en 1 minute 👌",
      #   body: "Grâce à cette petite vidéo, le réseau Entourage n'aura plus aucun secret pour vous 👀",
      #   image_url: true,
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 26,
      #   title: "Votre avis nous intéresse !",
      #   body: "On vous a concocté un questionnaire qui déchire (comme dirait Kenny du Comité de la Rue d'Entourage) et qui ne prend que 4 minutes et 23 secondes ;)",
      #   image_url: true,
      #   action: "Répondre",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 27,
      #   title: "Top 10 des plus belles actions",
      #   body: "Des rencontres, des témoignages, des amitiés ! Venez découvir toutes ces belles histoires qui ont eu lieu sur le réseau Entourage !",
      #   image_url: true,
      #   action: "Lire",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 28,
      #   title: "Un témoignage qui fait chaud au coeur ❤️",
      #   body: "Découvrez la rencontre entre Eric & Nolwenn via l'application Entourage ! N'hésitez pas à partager la vidéo 👌",
      #   image_url: true,
      #   action: "Voir la vidéo",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 29,
      #   title: "Agissez avec nous pour faire grandir le réseau de la solidarité !",
      #   body: "Nous vous avons concocté des petits outils qui vont vous permettre d'inviter les personnes sans-abri à rejoidnre le réseau Entourage 👌",
      #   image_url: true,
      #   action: "Voir",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 30,
      #   title: "Vous recherchez un emploi ? Entourage peut vous aider !",
      #   body: "Vous êtes demandeur d'emploi, vous accompagnez une personne qui est prête à travailler, vous connaissez quelqu'un qui recherche un emploi ... Nous lançons notre dispositif au service de l’emploi des personnes sans-abri !",
      #   image_url: true,
      #   action: "En savoir plus",
      #   url: "#{ENV['DEEPLINK_SCHEME']}://entourage/eeDYzdwp6di8",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 31,
      #   title: "Vous êtes en précarité et vous cherchez un job ? Participez à l'expérimentation Entourage.",
      #   body: "Nous croyons au pouvoir du réseau : et si les voisins pouvaient relayer les CV des personnes en précarité ? Rejoignez cette action si vous cherchez du travail, ou si vous êtes prêts à entourer ceux qui en cherchent !",
      #   image_url: true,
      #   action: "Rejoindre",
      #   url: "#{ENV['DEEPLINK_SCHEME']}://entourage/eeDYzdwp6di8",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      # announcements.push Announcement.new(
      #   id: 43,
      #   title: "Alerte canicule ! Soyons vigilants à tous les voisins 👌",
      #   body: "Comment aider les personnes sans-abri en cas de grandes chaleurs ? Voici quelques conseils pour aider au mieux les personnes SDF à supporter la chaleur…",
      #   image_url: true,
      #   action: "En savoir plus !",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

      announcements.push Announcement.new(
        id: 44,
        title: "Un partage peut tout changer",
        body: "Trouvons du travail à ces 15 personnes en précarité, en partageant leur CV sur nos réseaux !",
        image_url: true,
        action: "Partagez un CV",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false
      )

      service_civique_id =
        case area
        when 'Paris République', 'Paris 17 et 9', 'Paris 15', 'Paris 5', 'Paris'
          39
        when 'Lyon Ouest', 'Lyon Est', 'Lyon'
          40
        when 'Lille'
          41
        else
          42
        end

      announcements.push Announcement.new(
        id: service_civique_id,
        title: "Entourage recrute ses futurs volontaires en Service Civique",
        body: "Tu as entre 18 et 25 ans, et l’expérience en association te motive ? Deviens volontaire en service civique chez Entourage !",
        image_url: true,
        action: "Découvrir l’offre !",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: false
      )

      conversation_uuid = ConversationService.uuid_for_participants(
        [
          User.find_by(email: "guillaume@entourage.social").id,
          user.id
        ],
        validated: false
      )
      conversation_url = "#{ENV['DEEPLINK_SCHEME']}://entourage/#{conversation_uuid}"

      announcements.push Announcement.new(
        id: 35,
        title: "Guillaume, toujours à votre écoute.",
        body: "Hello, je suis le modérateur du réseau : je suis là pour vous accompagner et vous orienter. Contactez-moi si vous avez la moindre question !",
        image_url: true,
        action: "Contacter Guillaume",
        url: conversation_url,
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 32,
        title: "Rachid est une personne SDF, Marie une voisine... ils témoignent de leur rencontre !",
        body: "Regards croisés sur une main tendue.",
        image_url: true,
        action: "Voir la vidéo",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 33,
        title: "Ces actions ont été de vrais succès !",
        body: "Ça fait toujours du bien de s'inspirer de ce qui fonctionne ! Voici les initiatives du réseau Entourage qui ont abouti, et créé plus de chaleur humaine dans les rues.",
        image_url: true,
        action: "Lire les succès",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 34,
        title: "Au coeur d'Entourage : le Comité de la rue !",
        body: %(Ils sont 9 personnes et ont tous connu la rue (ou y vivent encore actuellement) : ils sont le "poumon" du projet.),
        image_url: true,
        action: "Les rencontrer",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 36,
        title: "La philosophie de notre asso en 1'30",
        body: "On l'aime beaucoup cette vidéo : elle illustre parfaitement notre mission de création de lien social entre voisins avec et sans-abri.",
        image_url: true,
        action: "Regarder",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 37,
        title: "En panne d'inspiration ?",
        body: "On vous donne ici plein d'idées d'actions à créer pour favoriser la solidarité dans le quartier.",
        image_url: true,
        action: "Je m'inspire",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      announcements.push Announcement.new(
        id: 38,
        title: "Comment devient-on SDF ?",
        body: "Une vidéo d'animation pour montrer comment la rupture des liens mène progressivement à la rue.",
        image_url: true,
        action: "Mieux comprendre",
        author: User.find_by(email: "guillaume@entourage.social"),
        webview: true
      )

      # announcements.push Announcement.new(
      #   id: ,
      #   title: "",
      #   body: "",
      #   image_url: true,
      #   action: "",
      #   author: User.find_by(email: "guillaume@entourage.social"),
      #   webview: true
      # )

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
