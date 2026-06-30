class UserBadge < ApplicationRecord
  ALL_TAGS = %w[bienvenue premier_contact moteur_rencontres fidele_papotages voix_presente].freeze

  def self.display_data_for(tag, locale: I18n.locale)
    return nil unless ALL_TAGS.include?(tag)

    {
      nom: I18n.t("email.badge.#{tag}.nom", locale: locale),
      description: I18n.t("email.badge.#{tag}.description", locale: locale)
    }
  end

  def self.badge_image_url(tag)
    "#{ENV['WEBSITE_URL']}/badges/#{tag}.svg"
  end

  DEFAULT_METADATA = {
    'bienvenue'          => {},
    'premier_contact'    => {},
    'moteur_rencontres'  => { 'current' => 0, 'target' => 3 },
    'fidele_papotages'   => { 'current' => 0, 'target' => 3 },
    'voix_presente'      => { 'current' => 0, 'target' => 3 }
  }.freeze

  belongs_to :user

  validates_uniqueness_of :badge_tag, scope: :user_id

  scope :active, -> { where(active: true) }

  def self.all_for_user(user)
    existing = where(user_id: user.id).index_by(&:badge_tag)

    ALL_TAGS.map do |tag|
      existing[tag] || new(
        user_id: user.id,
        badge_tag: tag,
        active: false,
        awarded_at: nil,
        metadata: DEFAULT_METADATA[tag]
      )
    end
  end
end
