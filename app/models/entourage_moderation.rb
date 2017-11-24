class EntourageModeration < ActiveRecord::Base
  validates :entourage_id, presence: true

  VALUES = {
    # Emetteur
    action_author_type: [
      'Riverain',
      'SDF',
      'Association',
      'Réseau ATD',
      'Réseau Entourage',
    ],
    # Destinataire
    action_recipient_type: [
      'SDF',
      'Riverain',
      'Association',
      'Réseau Entourage',
      'Tout le monde',
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
      "Message vocal laissé",
      "Mail envoyé",
      "Message via appli",
      "Appel + Mail",
      "Message vocal + Mail",
      "Pas besoin d'accompagnement",
    ],
    # Interlocuteur
    moderator: [
      'Guillaume',
      'Célia',
      'Jade',
      'Lucie',
      'Axelle',
      'Claire',
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
      'Non',
      'Hors communauté',
      'Doublon',
      'Hors sujet',
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
end
