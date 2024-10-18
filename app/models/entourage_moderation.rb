class EntourageModeration < ApplicationRecord
  include Sectionable

  validates_presence_of :entourage
  belongs_to :entourage
  belongs_to :moderator, class_name: :User, optional: true # about 30% of records have null moderator_id

  after_commit :auto_post_at_create

  SUCCESSFUL_VALUES = ["Oui", "Échange de coordonnées", "Orientation via modérateur"]

  VALUES = {
    # Emetteur. community.targeting_profiles + the following:
    action_author_type: [
      'Riverain',
      'SDF',
      'Association',
      'Ambassadeur',
      'Comité de la rue',
      'Équipe Entourage',
    ],
    # Type d’action
    action_type: [
      "Autre",
      "Autre : Information",
      "Mat : Alimentaire",
      "Mat : Argent",
      "Mat : Équipement",
      "Mat : Hébergement",
      "Mat : hors alim, hyg, vest, hébergement, argent",
      "Mat : Hygiène",
      "Mat : Vestimentaire",
      "Non Mat : Mise à disposition espace, douche, lessive, voiture, temps etc.",
      "Non Mat : Bénévolat hors maraudes",
      "Non Mat : Compétence hors Médical",
      "Non Mat : Emploi / Formation",
      "Non Mat : Maraude",
      "Non Mat : Médical",
      "Non Mat : soins animaliers",
      "Social : Évènement Entourage",
      "Social : Évenement non Entourage",
      "Social : Lien",
      "Hors sujet",
    ],
    # Consentement
    action_recipient_consent_obtained: [
      'Oui',
      'Non',
      'Non applicable',
    ],

    # Moyen de contact
    moderation_contact_channel: [
      "Appelé",
      "SMS",
      "Message vocal laissé",
      "Mail envoyé",
      "Message via appli",
      "Appel + Mail",
      "Message vocal + Mail",
      "Pas besoin d'accompagnement",
    ],
    # Action
    moderation_action: [
      'Orthographe',
      'Ethique',
      'Mise en forme',
      'Aucune',
      'Masqué',
    ],

    # Aboutissement
    action_outcome: [
      'Oui',
      'Échange de coordonnées',
      'Orientation via modérateur',
      'Non',
      'Hors communauté',
      'Hors sujet',
      'Blacklisté',
      'Doublon',
    ],
    # Raison de la réussite
    action_success_reason: [
      "Mise en relation",
      "Création de lien",
      "Donnation",
      "Transmission d'information",
      "Succès de l'apéro",
    ],
    # Raison de l'échec
    action_failure_reason: [
      "Personne n'a rejoint l'action",
      "Le créateur de l'action ne répond plus",
      "Pas de message échangé",
      "Personne n'était disponible",
      "Personne ne s'est présenté au RDV",
      "Le bénéficiare perdu de vue",
      "Un utilisateur ne répond plus",
      "Sans consentement",
    ],
  }

  def validated?
    validated_at.present?
  end

  def auto_post_at_create
    return unless validated?
    return unless saved_change_to_validated_at?
    return unless entourage.present?
    return unless entourage.action?
    return unless entourage.ongoing?
    return unless entourage.auto_post_at_create?
    return unless default_neighborhood = entourage.user.default_neighborhood
    return unless join_request = JoinRequest.find_by(joinable: default_neighborhood, user: entourage.user, status: :accepted)

    return if auto_post_already_created_on?(default_neighborhood, entourage)

    ChatServices::ChatMessageBuilder.new(
      params: {
        content: "#{entourage.title}\n\n#{entourage.description}",
        auto_post_type: entourage.action_class.to_s,
        auto_post_id: entourage.id
      },
      user: entourage.user,
      joinable: default_neighborhood,
      join_request: join_request
    ).create
  end

  private

  def auto_post_already_created_on? instance, entourage
    return unless instance.respond_to?(:chat_messages)

    instance
      .chat_messages
      .where("options->>'auto_post_type' = ?", entourage.action_class.to_s)
      .where("options->>'auto_post_id' = ?", entourage.id.to_s)
      .exists?
  end
end
