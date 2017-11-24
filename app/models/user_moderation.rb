class UserModeration < ActiveRecord::Base
  validates :user_id, presence: true

  VALUES = {
    # Attentes
    expectations: [
      "Connaissance du public SDF",
      "Devenir bénévole",
      "Etre accompagné dans la création du lien",
      "Echanger avec des professionnels",
      "Trouver des solutions",
      "Contirbuer avec des dons",
      "Créer du lien",
      "Pas d'attente",
    ],
    # Connaissance d’Entourage
    acquisition_channel: [
      'Facebook',
      'Twitter',
      'Instagram',
      'Internet',
      'TV',
      'Connaissance',
      'Autre',
      'Média',
    ],
    # Contenu envoyé
    content_sent: [
      'Facebook',
      'Twitter',
      'Instagram',
      'Internet',
      'TV',
      'Connaissance',
      'Autre',
      'Média',
    ],
    # Compétence
    skills: [
      'Administratif',
      'Médical',
      'Culturel',
      'Juridique',
      'Informatique',
      'Travaux',
      'Linguistique',
      'Aucune',
      'Travailleur social',
      'CV / Emploi',
    ],
  }
end
