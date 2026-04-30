class UserBadge < ApplicationRecord
  belongs_to :user

  validates_presence_of :user_id, :badge_tag, :awarded_at
  validates_uniqueness_of :badge_tag, scope: :user_id

  scope :active, -> { where(active: true) }

  def self.badges_config
    {
      bienvenue: { reversible: false, target: 1 },
      premier_contact: { reversible: false, target: 1 },
      moteur_rencontres: { reversible: true, target: 3 },
      fidele_papotages: { reversible: true, target: 6 },
      voix_presente: { reversible: true, target: 3 }
    }
  end
end
