class UserBadge < ApplicationRecord
  ALL_TAGS = %w[bienvenue premier_contact moteur_rencontres fidele_papotages voix_presente].freeze
  BUCKET_PREFIX = "badges"

  def self.display_data_for(tag, locale: I18n.locale)
    return nil unless ALL_TAGS.include?(tag)

    {
      nom: I18n.t("email.badge.#{tag}.nom", locale: locale),
      description: I18n.t("email.badge.#{tag}.description", locale: locale)
    }
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

  def share_url
    self.share_url_for_badge_tag(badge_tag)
  end

  class << self
    def share_url
      "#{ENV['MOBILE_HOST']}/app/badges"
    end

    def bucket
      Storage::Client.images
    end

    def image_url_for badge_tag
      bucket.public_url(key: path(badge_tag))
    end

    def path badge_tag
      "#{BUCKET_PREFIX}/#{badge_tag}.png"
    end
  end

  class << self
    def share_url_for_badge_tag badge_tag
      return Entourage.share_url(:outings) if badge_tag == 'moteur_rencontres'
      return Entourage.share_url(:papotages) if badge_tag == 'fidele_papotages'
      return Neighborhood.share_url if badge_tag == 'voix_presente'

      "#{ENV['MOBILE_HOST']}/app/badges/#{badge_tag}"
    end

    def bucket
      Storage::Client.images
    end

    def image_url_for badge_tag
      bucket.public_url(key: path(badge_tag))
    end

    def path badge_tag
      "#{BUCKET_PREFIX}/#{badge_tag}.png"
    end
  end
end
