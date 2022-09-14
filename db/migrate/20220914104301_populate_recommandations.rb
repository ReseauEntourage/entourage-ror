class PopulateRecommandations < ActiveRecord::Migration[5.2]
  def up
    get_attributes.each do |attributes|
      Recommandation.new(attributes).save
    end
  end

  def down
    Recommandation.delete_all
  end

  def get_attributes
    [
    # Fragment 0
    {
      fragment: 0,
      position_offer_help: 0,
      position_ask_for_help: 0,
      name: "Vidéo Entourage, un peu de chaleur humaine",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 1,
      name: "Article présentation carte POIs : où trouver des adresses solidaires pour m'aider ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 2,
      name: "Formulaire typeform orientation",
      instance: :webview,
      action: :show,
      argument_value: "url_to_typeform", # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 3,
      name: "Article Aides sociales : comment y avoir accès ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 4,
      name: "Vidéo Le Comité de la Rue, organe essentiel d'Entourage",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 5,
      name: "Article Des idées d'actions faciles à réaliser sur l'app !",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 1,
      position_ask_for_help: nil,
      name: "Vidéo Comment devient-on SDF ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 2,
      position_ask_for_help: nil,
      name: "Vidéo SDF, et si on comprenait ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 3,
      position_ask_for_help: nil,
      name: "S'inscrire à une sensibilisation en ligne - général",
      instance: :webview,
      action: :show,
      argument_value: "url_to_eventbrite", # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 4,
      position_ask_for_help: 6,
      name: "Vidéo Loopsider Le combat d'Eric, sans-abri à Paris",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 7,
      name: "Vidéo J’ai ouvert mon WiFi à mes voisins",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 5,
      position_ask_for_help: nil,
      name: "Vidéo Personnes sans-domicile-fixe : et si on changeait de regard ? ",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 6,
      position_ask_for_help: 8,
      name: "Vidéo Paroles de femmes sans-domicile-fixe",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 7,
      position_ask_for_help: nil,
      name: "S'inscrire à une sensibilisation en ligne - Spécial Femmes",
      instance: :webview,
      action: :show,
      argument_value: "url_to_eventbrite", # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 8,
      position_ask_for_help: 9,
      name: "Vidéo Regards croisés : Rachid & Marie",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: nil,
      position_ask_for_help: 10,
      name: "Vidéo L'urgence sociale : qui fait quoi ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 0,
      position_offer_help: 9,
      position_ask_for_help: nil,
      name: "Vidéo Personnes sans-domicile-fixe : et si on agissait ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help],
      status: :active,
    },

    # Fragment 1
    {
      fragment: 1,
      position_offer_help: 0,
      position_ask_for_help: 0,
      name: "Découvrir / dire bonjour à mon groupe de voisins local ",
      instance: :neighborhood,
      action: :show_joined,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 1,
      position_ask_for_help: 1,
      name: "Découvrir les événements",
      instance: :outing,
      action: :index,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 2,
      position_ask_for_help: 2,
      name: "Découvrir les groupes à proximité",
      instance: :neighborhood,
      action: :index,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 3,
      position_ask_for_help: 3,
      name: "Rejoindre un groupe",
      instance: :neighborhood,
      action: :join,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 4,
      position_ask_for_help: 4,
      name: "Participer à un événement",
      instance: :outing,
      action: :show_not_joined,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 5,
      position_ask_for_help: 5,
      name: "Tuto app - Comment créer un événement ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 6,
      position_ask_for_help: 6,
      name: "Créer un événement",
      instance: :outing,
      action: :new,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 7,
      position_ask_for_help: nil,
      name: "Proposer un café",
      instance: :contribution,
      action: :new,
      argument_value: nil,
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 8,
      position_ask_for_help: 7,
      name: "Tuto app - Comment créer un groupe ?",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 1,
      position_offer_help: 9,
      position_ask_for_help: 8,
      name: "Créer un groupe",
      instance: :neighborhood,
      action: :new,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    },

    # Fragment 2
    {
      fragment: 2,
      position_offer_help: 0,
      position_ask_for_help: 0,
      name: "Liste des demandes à proximité",
      instance: :solicitation,
      action: :index,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 1,
      position_ask_for_help: nil,
      name: "Répondre à une demande",
      instance: :solicitation,
      action: :show,
      argument_value: nil,
      user_goals: [:offer_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 2,
      position_ask_for_help: 4,
      name: "Préparer la rencontre",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 3,
      position_ask_for_help: 1,
      name: "Tuto ce que je peux donner / ne pas donner",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:ask_for_help, :offer_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 4,
      position_ask_for_help: 2,
      name: "La Charte éthique en qlq mots",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 5,
      position_ask_for_help: 5,
      name: "Proposer de l'aide",
      instance: :contribution,
      action: :new,
      argument_value: nil,
      user_goals: [:offer_help, :ask_for_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: nil,
      position_ask_for_help: 3,
      name: "Demander de l'aide",
      instance: :solicitation,
      action: :new,
      argument_value: nil,
      user_goals: [:ask_for_help],
      status: :active,
    }, {
      fragment: 2,
      position_offer_help: 6,
      position_ask_for_help: nil,
      name: "Article “Comment relayer les demandes à son réseau de quartier”",
      instance: :resource,
      action: :show,
      argument_value: 1, # to be changed
      user_goals: [:offer_help],
      status: :active,
    }, ]

  end
end

