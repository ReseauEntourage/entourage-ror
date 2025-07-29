@announcements = []
@announcements.push  Announcement.new(
  id: 1,
  title: 'Et si on comprenait le monde de la rue ?',
  body: 'Préjugés sur les personnes sans-abri : 3 minutes pour changer son regard !',
  action: 'Voir',
)

@announcements.push Announcement.new(
  id: 2,
  title: 'Une autre façon de contribuer !',
  body: 'Entourage a besoin de votre soutien pour continuer sa mission.',
  action: 'Aider',
  webview: false
)

@announcements.push Announcement.new(
  id: 3,
  title: '{first_name} ne manquez pas les actions autour de vous !',
  body: "Définissez votre zone d'action pour être tenu(e) informé(e) des actions dans votre quartier.",
  action: 'Définir ma zone',
  webview: true
)

@announcements.push Announcement.new(
  id: 4,
  title: 'En 2018, osez la rencontre !',
  body: 'Découvrez des conseils concrets pour aller vers les personnes sans-abri.',
  action: 'Voir',
  webview: true
)

@announcements.push Announcement.new(
  id: 5,
  title: '???',
  body: '???',
  action: '???',
)

@announcements.push Announcement.new(
  id: 6,
  title: 'Le saviez-vous ? Chaque action est contrôlée.',
  body: "L'équipe de modération d'Entourage veille au respect des personnes et de la vie privée.",
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 7,
  title: 'Le top 5 des belles actions !',
  body: 'Découvrez les initiatives solidaires qui ont abouti grâce au réseau',
  action: 'Inspirez-vous',
  webview: true
)

@announcements.push Announcement.new(
  id: 8,
  title: %(Le "Comité de la rue", qu'est-ce que c'est ?),
  body: "Saviez-vous qu'Entourage est co-construit avec des personnes SDF ? ",
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 9,
  title: 'Fête des Voisins 2018 : invitez vos voisins SDF !',
  body: 'vendredi 25 mai 2018, invitons TOUS les voisins à partager un moment : parlez-en aux personnes sans-abri de votre quartier',
  action: "J'agis",
  webview: true
)

@announcements.push Announcement.new(
  id: 10,
  title: 'Besoin d’aide ? Contactez Guillaume',
  body: 'Une question, une information ? Le modérateur de l’équipe est la pour répondre à toutes vos demandes !',
  action: 'Je contacte',
  url: 'entourage://entourage/1_list_me-moderator',
  webview: false
)

@announcements.push Announcement.new(
  id: 11,
  title: "{first_name} n'attendez plus pour agir !",
  body: "Conseils, rencontres, idées d'action auprès des SDF... Passez à l'action en discutant avec vos voisins solidaires.",
  action: "J'agis",
  webview: true
)

@announcements.push Announcement.new(
  id: 12,
  title: '{first_name} découvrez les belles histoires sur notre blog !',
  body: 'Aujourd’hui, on vous partage la belle histoire de Roya-Rose (riveraine) et de Michael (sans-abri) 👌',
  action: 'Découvrir',
  webview: true
)

@announcements.push Announcement.new(
  id: 14,
  title: "Participez à l'élan de générosité",
  body: "Entourage a besoin de votre soutien pour réchauffer le cœur des sans-abri en cette fin d'année",
  action: 'Je fais un don',
  webview: false
)

@announcements.push Announcement.new(
  id: 15,
  title: "Opé calendrier de l'avent inversé",
  body: 'L’idée ? Chaque jour du mois de Décembre, mettez un petit cadeau dans une boîte que vous irez offrir à un voisin démuni le jour de Noël',
  action: 'Je me lance',
  webview: true
)

@announcements.push Announcement.new(
  id: 16,
  title: 'Où passer un réveillon solidaire ?',
  body: 'On a répertorié pour vous les initiatives qui ont besoin de vous, auprès des personnes SDF',
  action: 'Découvrir',
  webview: true
)

@announcements.push Announcement.new(
  id: 17,
  title: '3,2,1 ... Bonne année 🎉',
  body: "Toute l'équipe Entourage vous souhaite une bonne année 2019 ! Que celle-ci vous remplisse de joie et de bonheur 👌 Ensemble répandons la chaleur humaine dans nos rues 👫",
  action: '#chaleurhumaine',
  webview: true
)

@announcements.push Announcement.new(
  id: 18,
  title: 'Bonne résolution #1',
  body: "Et si on commencait 2019, en s'intéressant au monde de la rue pour le comprendre ? Découvrez notre guide pédagogique \"Simple comme Bonjour\" pour créer du lien avec vos voisins sans-abri et avoir des conseils concrets !",
  action: 'Voir la vidéo',
  webview: true
)

@announcements.push Announcement.new(
  id: 19,
  title: '❄️❄️ Grrrr ❄️❄️',
  body: "Le grand froid est arrivé ! Comment faire pour aider les personnes sans-abri à son échelle ? Pas d'inquiétude on vous explique. 👌",
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 20,
  title: 'Bonne résolution #2',
  body: "Comprendre la rue passe aussi par écouter les témoignages de ceux qui l'ont vécu. Cette semaine, parole aux femmes SDF 👩🏽.",
  action: 'Voir la vidéo',
  webview: true
)

@announcements.push Announcement.new(
  id: 21,
  title: 'Les fêtes de Noël Entourage en photos',
  body: 'Les "Talents de la rue" sont montés sur scène pour le réveillon, et ça valait le détour.',
  action: 'Je regarde',
  webview: true
)

@announcements.push Announcement.new(
  id: 22,
  title: "Envie d'en savoir plus ?",
  body: %("Simple comme Bonjour" le guide pour aller à la rencontre des personnes sans-abri ! Décrouvrez les vidéos, les interviews, les témoignages et le guide),
  action: 'Voir',
  webview: true
)

@announcements.push Announcement.new(
  id: 23,
  title: 'Suivez-nous sur les réseaux !',
  body: 'Retrouvez Entourage également sur tous vos réseaux sociaux ! Suivez toute nos actualités, photos, vidéos, belles histoires !',
  action: 'Je rejoins',
  webview: false
)

@announcements.push Announcement.new(
  id: 24,
  title: 'Entourage débarque sur votre ordinateur !',
  body: "Retrouvez dès maintenant l'application Entourage sur votre ordinateur, directement sur le site internet www.entourage.social/app !",
  action: 'Voir',
  webview: false
)

@announcements.push Announcement.new(
  id: 25,
  title: 'Comprendre Entourage en 1 minute 👌',
  body: "Grâce à cette petite vidéo, le réseau Entourage n'aura plus aucun secret pour vous 👀",
  action: 'Voir',
  webview: true
)

@announcements.push Announcement.new(
  id: 26,
  title: 'Votre avis nous intéresse !',
  body: "On vous a concocté un questionnaire qui déchire (comme dirait Kenny du Comité de la Rue d'Entourage) et qui ne prend que 4 minutes et 23 secondes ;)",
  action: 'Répondre',
  webview: true
)

@announcements.push Announcement.new(
  id: 27,
  title: 'Top 10 des plus belles actions',
  body: 'Des rencontres, des témoignages, des amitiés ! Venez découvir toutes ces belles histoires qui ont eu lieu sur le réseau Entourage !',
  action: 'Lire',
  webview: true
)

@announcements.push Announcement.new(
  id: 28,
  title: 'Un témoignage qui fait chaud au coeur ❤️',
  body: "Découvrez la rencontre entre Eric & Nolwenn via l'application Entourage ! N'hésitez pas à partager la vidéo 👌",
  action: 'Voir la vidéo',
  webview: true
)

@announcements.push Announcement.new(
  id: 29,
  title: 'Agissez avec nous pour faire grandir le réseau de la solidarité !',
  body: "Nous vous avons concocté des petits outils qui vont vous permettre d'inviter les personnes sans-abri à rejoidnre le réseau Entourage 👌",
  action: 'Voir',
  webview: true
)

@announcements.push Announcement.new(
  id: 30,
  title: 'Vous recherchez un emploi ? Entourage peut vous aider !',
  body: "Vous êtes demandeur d'emploi, vous accompagnez une personne qui est prête à travailler, vous connaissez quelqu'un qui recherche un emploi ... Nous lançons notre dispositif au service de l’emploi des personnes sans-abri !",
  action: 'En savoir plus',
  url: 'entourage://entourage/eeDYzdwp6di8',
  webview: true
)

@announcements.push Announcement.new(
  id: 31,
  title: "Vous êtes en précarité et vous cherchez un job ? Participez à l'expérimentation Entourage.",
  body: 'Nous croyons au pouvoir du réseau : et si les voisins pouvaient relayer les CV des personnes en précarité ? Rejoignez cette action si vous cherchez du travail, ou si vous êtes prêts à entourer ceux qui en cherchent !',
  action: 'Rejoindre',
  url: 'entourage://entourage/eeDYzdwp6di8',
  webview: true
)

@announcements.push Announcement.new(
  id: 43,
  title: 'Alerte canicule ! Soyons vigilants à tous les voisins 👌',
  body: 'Comment aider les personnes sans-abri en cas de grandes chaleurs ? Voici quelques conseils pour aider au mieux les personnes SDF à supporter la chaleur…',
  action: 'En savoir plus !',
  webview: true
)

@announcements.push Announcement.new(
  id: 45,
  title: 'Alerte canicule ! Vigilance pour les plus fragiles 👌',
  body: 'Comment aider les personnes sans-abri en cas de grandes chaleurs ? Quelques conseils pour aider au mieux les personnes SDF !',
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 46,
  title: 'Vous êtes victimes ou témoins de violences conjugales, appelez le 3919',
  body: 'Le 3919 est le numéro national unique 7 jours sur 7 de 9h à 22h et de 9h à 18h les samedi, dimanche et jours fériés. En cas de danger immédiat, contactez la police (17) ou le SAMU (15).',
  action: 'Plus d’informations',
  webview: true
)

@announcements.push Announcement.new(
  id: 34,
  title: "Au coeur d'Entourage : le Comité de la rue !",
  body: %(Ils sont 9 personnes et ont tous connu la rue (ou y vivent encore actuellement) : ils sont le "poumon" du projet.),
  action: 'Les rencontrer',
  webview: true
)

@announcements.push Announcement.new(
  id: 47,
  title: 'Un smartphone dans un tiroir ?',
  body: "À la rue, c'est très utile. Entourage s'engage à les redistribuer aux personnes qui en ont besoin !",
  action: 'Donner mon smartphone',
  webview: false,
  url: 'mailto:guillaume@entourage.social'
)

@announcements.push Announcement.new(
  id: 49,
  title: 'Salon SEIS #4 à Rennes',
  body: 'RDV le 10 octobre de 9h à 17h au salon des Innovations Solidaires à Askoria (M° Villejean - Université)',
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 39,
  title: 'Entourage recrute ses futurs volontaires en Service Civique',
  body: 'Tu as entre 18 et 25 ans, et l’expérience en association te motive ? Deviens volontaire en service civique chez Entourage !',
  action: 'Découvrir l’offre !',
  webview: false
)
@announcements.push Announcement.new(
  id: 40,
  title: 'Entourage recrute ses futurs volontaires en Service Civique',
  body: 'Tu as entre 18 et 25 ans, et l’expérience en association te motive ? Deviens volontaire en service civique chez Entourage !',
  action: 'Découvrir l’offre !',
  webview: false
)
@announcements.push Announcement.new(
  id: 41,
  title: 'Entourage recrute ses futurs volontaires en Service Civique',
  body: 'Tu as entre 18 et 25 ans, et l’expérience en association te motive ? Deviens volontaire en service civique chez Entourage !',
  action: 'Découvrir l’offre !',
  webview: false
)
@announcements.push Announcement.new(
  id: 42,
  title: 'Entourage recrute ses futurs volontaires en Service Civique',
  body: 'Tu as entre 18 et 25 ans, et l’expérience en association te motive ? Deviens volontaire en service civique chez Entourage !',
  action: 'Découvrir l’offre !',
  webview: false
)

@announcements.push Announcement.new(
  id: 44,
  title: 'Un partage peut tout changer',
  body: 'Trouvons du travail à ces 15 personnes en précarité, en partageant leur CV sur nos réseaux !',
  action: 'Partagez un CV',
  webview: false
)

@announcements.push Announcement.new(
  id: 32,
  title: 'Rachid est une personne SDF, Marie une voisine... ils témoignent de leur rencontre !',
  body: 'Regards croisés sur une main tendue.',
  action: 'Voir la vidéo',
  webview: true
)

@announcements.push Announcement.new(
  id: 33,
  title: 'Ces actions ont été de vrais succès !',
  body: "Ça fait toujours du bien de s'inspirer de ce qui fonctionne ! Voici les initiatives du réseau Entourage qui ont abouti, et créé plus de chaleur humaine dans les rues.",
  action: 'Lire les succès',
  webview: true
)

@announcements.push Announcement.new(
  id: 36,
  title: "La philosophie de notre asso en 1'30",
  body: "On l'aime beaucoup cette vidéo : elle illustre parfaitement notre mission de création de lien social entre voisins avec et sans-abri.",
  action: 'Regarder',
  webview: true
)

@announcements.push Announcement.new(
  id: 37,
  title: "En panne d'inspiration ?",
  body: "On vous donne ici plein d'idées d'actions à créer pour favoriser la solidarité dans le quartier.",
  action: "Je m'inspire",
  webview: true
)

@announcements.push Announcement.new(
  id: 38,
  title: 'Comment devient-on SDF ?',
  body: "Une vidéo d'animation pour montrer comment la rupture des liens mène progressivement à la rue.",
  action: 'Mieux comprendre',
  webview: true
)

@announcements.push Announcement.new(
  id: 51,
  title: "Propagez l'Effet Entourage, faites un don",
  body: "En cette fin d'année, nous avons besoin de vous pour faire grandir le réseau solidaire et développer nos actions !",
  action: 'Faire un don',
  webview: false
)

@announcements.push Announcement.new(
  id: 52,
  title: 'Quelles sont VOS questions sur la rue',
  body: 'De nouveaux contenus à venir, basés sur vos besoins !',
  action: 'Je réponds',
  webview: true
)

@announcements.push Announcement.new(
  id: 53,
  title: "Bénévolat de fin d'année",
  body: 'Une liste des réveillons solidaires qui ont besoin de vous',
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 61,
  title: 'Coronavirus : comment aider ?',
  body: 'Nos conseils pour se rendre utile malgré le confinement.',
  action: "J'aide",
  webview: true
)

@announcements.push Announcement.new(
  id: 62,
  title: 'Orienter : quelles assos encore ouvertes ?',
  body: 'Distribution alimentaire, permanences... Tout est chamboulé. Soliguide vous oriente pour trouver des structures encore ouvertes.',
  action: "Je m'informe",
  webview: true
)

@announcements.push Announcement.new(
  id: 63,
  title: 'Gardons le lien malgré le Covid-19 ! ',
  body: "Vous avez envie de parler à du monde, d'échanger ? Un cercle d'entraide s'est créé : écrivez au 07 68 03 73 48",
  action: 'Je garde le lien',
  webview: true
)

@announcements.push Announcement.new(
  id: 64,
  title: 'Journal du confinement',
  body: "Le témoignage quotidien d'une personne SDF qui raconte sa façon de vivre le confinement.",
  action: 'Je découvre',
  webview: true
)

@announcements.push Announcement.new(
  id: 54,
  title: "Aider : des idées d'exemples concrets",
  body: "Une vidéo de 3 min' pour mieux comprendre son rôle de voisin",
  action: 'Je regarde la vidéo',
  webview: true
)

@announcements.push Announcement.new(
  id: 55,
  title: 'Votre asso organise un réveillon ?',
  body: "Partagez-nous vos infos pour qu'on les mette en valeur",
  action: 'Je réponds',
  webview: true
)

@announcements.push Announcement.new(
  id: 56,
  title: 'Vidéo Brut : Kenny, ex SDF',
  body: 'Le président du Comité de la rue raconte sa 1ère nuit à la rue',
  action: 'Je regarde',
  webview: false
)

@announcements.push Announcement.new(
  id: 57,
  title: "Calendrier de l'avent solidaire",
  body: 'Soyez gourmands de conseils avec ces 24 étapes pour créer plus du lien',
  action: 'Je découvre',
  webview: true
)

@announcements.push Announcement.new(
  id: 35,
  title: 'Guillaume, modérateur à votre écoute',
  body: 'Je suis là pour répondre à toutes vos questions et vous orienter',
  action: "J'échange avec Guillaume",
  url: 'entourage://entourage/1_list_me-moderator',
  webview: true
)

@announcements.push Announcement.new(
  id: 58,
  title: 'Sportif ?',
  body: "Rejoignez notre communauté d'entraide autour du sport !",
  action: 'En savoir plus',
  url: 'entourage://entourage/esL6R5Az6MeU',
  webview: false
)

@announcements.push Announcement.new(
  id: 59,
  title: 'Engager votre entreprise',
  body: 'Vous souhaitez engager votre boîte avec Entourage ? Nous avons des actions spéciales collaborateurs !',
  action: 'En savoir plus',
  webview: false,
  url: 'mailto:jonathan@entourage.social'
)

@announcements.push Announcement.new(
  id: 13,
  title: 'On recrute des bénévoles',
  body: 'Devenez ambassadeur dans votre quartier, 2h par semaine !',
  action: 'En savoir plus',
  webview: true
)

@announcements.push Announcement.new(
  id: 60,
  title: "D'un parking à un toit",
  body: "Partagez l'histoire de Mélanie, sortie de la rue grâce aux mains tendues du réseau",
  action: 'Je partage',
  webview: false
)

@announcements.push Announcement.new(
  id: 48,
  title: 'Votre histoire ?',
  body: 'Un beau moment partagé ? Racontez-nous.',
  action: 'Je partage',
  url: 'entourage://entourage/1_list_me-moderator',
  webview: true
)

@announcements.push Announcement.new(
  id: 50,
  title: "Je parle d'Entourage",
  body: "à mon entourage, pour les inciter à passer à l'action.",
  action: 'Je relaie',
  webview: false
)

icon = {
  2 => :heart,
  3 => :pin,
  4 => :video,
  5 => :megaphone,
  6 => :megaphone,
  7 => :trophy,
  8 => :heart,
  9 => :heart,
  10 => :heart,
  11 => :trophy,
  12 => :text,
  13 => :megaphone,
  14 => :heart,
  15 => :megaphone,
  16 => :pin,
  17 => :heart,
  18 => :video,
  19 => :megaphone,
  20 => :video,
  21 => :heart,
  22 => :megaphone,
  23 => :megaphone,
  24 => :heart,
  25 => :video,
  26 => :megaphone,
  27 => :heart,
  28 => :video,
  29 => :text,
  30 => :megaphone,
  31 => :pin,
  32 => :video,
  33 => :heart,
  34 => :heart,
  35 => :chat,
  36 => :video,
  37 => :trophy,
  38 => :video,
  39 => :megaphone,
  40 => :megaphone,
  41 => :megaphone,
  42 => :megaphone,
  43 => :megaphone,
  44 => :megaphone,
  45 => :megaphone,
  46 => :megaphone,
  47 => :heart,
  48 => :heart,
  49 => :info,
  50 => :chat,
  51 => :heart,
  52 => :question,
  53 => :heart,
  54 => :video,
  55 => :question,
  56 => :video,
  57 => :heart,
  58 => :heart,
  59 => :chat,
  60 => :video,
  61 => :heart,
  62 => :question,
  63 => :heart,
  64 => :chat,
}

@announcements.each { |a| a.icon = icon[a.id] }

urls = {
   2 => 'https:/www.entourage.social/don?firstname={first_name}&lastname={last_name}&email={email}&external_id={id}&utm_medium=APP&utm_campaign=DEC2017',
   3 => 'https://entourage-asso.typeform.com/to/WIg5A9?user_id={id}',
   4 => 'http://www.simplecommebonjour.org/?p=153',
   6 => 'https://blog.entourage.social/2018/01/15/securite-et-moderation/',
   7 => 'https://blog.entourage.social/2018/03/02/top-5-des-actions-reussies/',
   8 => 'https://blog.entourage.social/2017/07/28/le-comite-de-la-rue-quest-ce-que-cest/',
   9 => 'https://blog.entourage.social/2018/05/17/fete-des-voisins-2018-invitons-aussi-nos-voisins-sdf/',
  11 => 'https://blog.entourage.social/2017/04/28/quelles-actions-faire-avec-entourage/#site-content',
  12 => 'https://blog.entourage.social/2018/07/27/roya-michael-il-avait-besoin-dun-semblant-de-famille/',
  13 => 'https://www.entourage.social/devenir-ambassadeur',
  14 => 'https://entourage.iraiser.eu/mon-don/~mon-don',
  15 => 'https://blog.entourage.social/2018/11/30/noel-solidaire-faisons-tous-le-calendrier-de-lavent-inverse/',
  16 => 'https://blog.entourage.social/2018/11/29/noel-solidaire-2018-aupres-des-personnes-sdf-du-benevolat-pour-le-reveillon/',
  17 => 'https://www.entourage.social/',
  18 => 'http://www.simplecommebonjour.org/?p=8',
  19 => 'https://blog.entourage.social/2017/01/17/grand-froid-comment-aider-les-personnes-sans-abri-a-son-echelle/#site-content',
  20 => 'http://www.simplecommebonjour.org/?p=12',
  21 => 'https://blog.entourage.social/2019/01/02/soiree-de-noel-entourage-x-refettorio-la-rue-est-pleine-de-talents/#site-content',
  22 => 'http://www.simplecommebonjour.org/',
  23 => 'https://www.facebook.com/EntourageReseauCivique/',
  24 => 'https://www.entourage.social/app',
  25 => 'https://www.youtube.com/watch?v=AsUyal44DXk',
  26 => 'http://bit.ly/2tvGgcH',
  27 => 'https://blog.entourage.social/category/belles-histoires/#nav-search',
  28 => 'https://www.youtube.com/watch?v=UcODKwV9bO8&list=PLwLEgqe22sVYuK9ySGExo8JfgAzlqWUV9',
  29 => 'https://blog.entourage.social/2019/03/04/comment-puis-je-inviter-des-personnes-sdf-sur-le-reseau-entourage/#site-content',
  32 => 'https://www.youtube.com/watch?v=QXcUptypnOY',
  33 => 'https://blog.entourage.social/2017/07/06/appli-entourage-les-10-plus-belles-actions/#site-content',
  34 => 'https://blog.entourage.social/2017/07/28/le-comite-de-la-rue-entourage/#site-content',
  36 => 'https://www.youtube.com/watch?v=IYUo5WAZxXs',
  37 => 'https://blog.entourage.social/2017/04/28/quelles-actions-faire-avec-entourage/#site-content',
  38 => 'https://www.youtube.com/watch?v=Dk3bo__5dvs',
  39 => 'https://www.service-civique.gouv.fr/missions/paris-creer-du-lien-social-autour-des-personnes-sans-abri',
  40 => 'https://www.service-civique.gouv.fr/missions/lyon-creer-du-lien-social-autour-des-personnes-sans-abri',
  41 => 'https://www.service-civique.gouv.fr/missions/lille-creer-du-lien-social-autour-des-personnes-sans-abri',
  42 => 'https://www.welcometothejungle.co/fr/companies/entourage/jobs/developpement-de-communaute-voisins-avec-et-sans-abri_paris',
  43 => 'https://blog.entourage.social/2017/06/19/charles-aznavour-avait-tort-la-misere-nest-pas-moins-penible-au-soleil/#site-content',
  44 => 'https://www.linkedout.fr/',
  45 => 'https://blog.entourage.social/2017/06/19/charles-aznavour-avait-tort-la-misere-nest-pas-moins-penible-au-soleil/#site-content',
  46 => 'http://www.solidaritefemmes.org/',
  48 => 'https://entourage-asso.typeform.com/to/QeQ4X7?user_id={id}',
  49 => 'https://www.askoria.eu/seis/',
  50 => 'https://wa.me/?text=J%E2%80%99ai%20d%C3%A9couvert%20une%20super%20app%20qui%20permet%20d%E2%80%99aider%20facilement%20les%20personnes%20SDF%20pr%C3%A8s%20de%20chez%20soi%2C%20Entourage.%20Tu%20devrais%20la%20t%C3%A9l%C3%A9charger%20aussi%20%C3%A7a%20prend%2030%20secondes%20!%20bit.ly%2Fappentourage-w',
  51 => 'https://www.effet.entourage.social/?utm_medium=carteannonce&utm_source=app&utm_campaign=dons2019&utm_term=db{id}',
  60 => 'https://www.effet.entourage.social/?utm_medium=carteannonce&utm_source=app&utm_campaign=dons2019&utm_term=db{id}',
  52 => 'https://entourage-asso.typeform.com/to/pdm0w3',
  53 => 'https://blog.entourage.social/2019/12/04/noel-solidaire-2019-aupres-des-personnes-sdf-du-benevolat-pour-le-reveillon/#site-content',
  54 => 'http://www.simplecommebonjour.org/?p=169',
  55 => 'https://entourage-asso.typeform.com/to/MgHVyc?mc_user_id={id}',
  56 => 'https://www.facebook.com/watch/?v=402957420659669',
  57 => 'https://blog.entourage.social/2019/11/28/calendrier-de-lavent-solidaire-2019-24-jours-guides-par-entourage/#site-content',
  61 => 'https://blog.entourage.social/2020/03/13/covid-19-et-personnes-sdf-quelques-conseils/#site-content',
  62 => 'http://www.solinum.org/category/info-coronavirus/',
  63 => 'https://blog.entourage.social/2020/03/20/gardons-le-moral-convivialite-100-digitale-loin-des-yeux-pres-du-coeur-%f0%9f%a7%a1/#site-content',
  64 => 'https://blog.entourage.social/2020/03/18/journal-du-confinement-de-personnes-sdf/#site-content',
}

@announcements.each { |a| a.url ||= urls[a.id] }

image = {
  10 => 'guillaume.jpg',
  11 => 'action.jpg',
  13 => 'ambassadors-3.jpg',
  14 => 'collecte-2018.jpg',
  16 => 'noel.jpg',
  17 => '2.png',
  18 => 'scb.jpg',
  19 => 'grand-froid.png?2',
  20 => 'paroles-de-femmes.jpg',
  21 => 'talents-2018.jpg',
  22 => 'scb.jpg',
  23 => 'reseaux-sociaux.jpg',
  24 => 'webapp.jpg',
  25 => 'video-eric.jpg',
  26 => 'paperboard.jpg',
  27 => 'conversation.jpg',
  28 => 'video-nolwenn.jpg',
  29 => 'conversation-2.jpg',
  30 => 'ordinateur.jpg',
  31 => '31.jpg',
  32 => '32.jpg',
  33 => '33.jpg',
  34 => '34.jpg',
  35 => 'guillaume-3.jpg',
  36 => '36.jpg',
  37 => '37.jpg',
  38 => '38.jpg',
  39 => 'service-civique.jpg',
  40 => 'service-civique.jpg',
  41 => 'service-civique.jpg',
  42 => 'service-civique.jpg',
  43 => 'conversation-2.jpg',
  44 => 'linkedout.jpg',
  45 => 'canicule.jpg',
  46 => '3919.png',
  47 => 'stat-smartphone.png',
  48 => 'verbatims-2.jpg',
  49 => 'seis-4.png',
  50 => '50.jpg',
  51 => 'don-2019.jpg',
  52 => '52.jpg',
  53 => '53.jpg',
  54 => '54.jpg',
  55 => '55.jpg',
  56 => '56.jpg',
  57 => '57.jpg',
  58 => '58.jpg',
  59 => '59.jpg',
  60 => '60.jpg',
  61 => '61-2.jpg',
  62 => '62.jpg',
  63 => '63.jpg',
  64 => '64.jpg',
}

host = {'production'=>'https://api.entourage.social', 'development'=>'http://gregbook.local:8080'}[Rails.env]
@announcements.each { |a| next if image[a.id].nil?; a.image_url = "#{host}/assets/announcements/images/#{image[a.id]}" }

@announcements.each { |a| a.status = :archived }

published = [61, 62, 63, 64, 54, 56, 35, 58, 59, 13, 48, 50]
@announcements.each do |a|
  i = published.index(a.id)
  next if i.nil?
  a.status = :active
  a.position = i + 1
end

# ActiveRecord::Base.connection.execute("ALTER SEQUENCE announcements_id_seq RESTART WITH #{Announcement.maximum(:id) + 1}")
