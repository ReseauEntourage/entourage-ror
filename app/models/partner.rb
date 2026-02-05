class Partner < ApplicationRecord
  include CoordinatesScopable
  include Imageable
  include Orientable

  CONTENT_TYPES = ['image/png', 'image/jpeg'].freeze
  POSTAL_CODE_REGEX = /\b\d{5}\b/

  has_many :users
  has_many :groups, through: :users

  has_many :followings, dependent: :delete_all
  has_many :followers, through: :followings, source: :user
  has_many :partner_invitations, dependent: :delete_all
  has_many :partner_join_requests, dependent: :delete_all
  has_one :poi, dependent: :delete

  validates :name, presence: true
  validates :address, presence: true
  validates :longitude, :latitude, numericality: true, presence: true
  validate :validate_uniqueness!

  before_save :reformat_url, if: :website_url_changed?
  before_save :reformat_needs, if: :needs_changed?
  before_save :geocode, if: :address_changed?
  before_save :refresh_postal_code, if: :should_refresh_postal_code?
  before_save :update_searchable_text
  after_create :signal_creation
  after_commit :sync_poi

  geocoded_by :address

  attr_accessor :following # see api/v1/partners#show

  # @warning Partner should be deactivable; currently, only erase is possible
  scope :active, -> {}

  scope :staff, -> { where(staff: true).ordered }
  scope :no_staff, -> { where(staff: false).ordered }
  scope :ordered, -> { order(:name) }

  scope :same_as_partner, -> (partner) {
    return unless partner.name.present?
    return unless partner.address.present?

    search_by(partner.name)
      .where.not(id: partner.id)
      .where('address ILIKE ?', "%#{partner.postal_code}%")
  }

  scope :search_by, -> (query) {
    return unless query.present?

    where("searchable_text ILIKE ?", "%#{
      I18n.transliterate(query).strip.downcase
    }%")
  }

  PLACEHOLDER_URL = 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/partner-placeholder.png'.freeze

  # @caution we should have a deleted status
  def deleted?
    false
  end

  class << self
    def bucket
      Storage::Client.avatars
    end

    def bucket_prefix
      "#{table_name}/logo"
    end
  end

  # @param force true to bypass deletion
  def image_url force = false
    return if deleted? && !force

    self[:image_url]
  end

  def image_url_with_bucket
    return unless image_url

    Partner.path(image_url)
  end

  def image_path force = false
    return unless image_url(force).present?

    Partner.url_for(image_url(force))
  end

  def image_url_with_size size, force = false
    return unless image_url(force).present?

    Partner.url_for_with_size(image_url(force), size)
  end

  def reformat_url
    self.website_url = website_url&.gsub(/\s+/, '').presence
    return if website_url.nil?
    return if website_url.start_with?(%r(https?://)i)
    self.website_url = "http://#{website_url}"
  end

  def reformat_needs
    self.donations_needs  = donations_needs&.strip.presence
    self.volunteers_needs = volunteers_needs&.strip.presence
  end

  def description_with_needs
    blocks = []
    description = self.description&.strip.presence
    blocks << description if description
    blocks << "Dons acceptés :\n#{donations_needs}" if donations_needs
    blocks << "Bénévoles recherchés :\n#{volunteers_needs}" if volunteers_needs
    blocks.join("\n\n")
  end

  def signal_creation
    return unless users.any?

    SlackServices::PartnerCreate.new(partner: self).notify
  end

  def sync_poi
    return if self.destroyed?

    poi = Poi.find_or_initialize_by(partner_id: self.id)

    poi.name        = self.name
    poi.description = self.description
    poi.latitude    = self.latitude
    poi.longitude   = self.longitude
    poi.adress      = self.address
    poi.phone       = self.phone
    poi.website     = self.website_url
    poi.email       = self.email
    poi.audience    = nil
    poi.category_id = 8
    poi.validated   = self.geocoded?

    poi.save
  end

  protected

  def update_searchable_text
    self.searchable_text = I18n.transliterate(name.downcase)
  end

  private

  def needs_changed?
    donations_needs_changed? || volunteers_needs_changed?
  end

  def should_refresh_postal_code?
    will_save_change_to_latitude? || will_save_change_to_longitude?
  end

  def refresh_postal_code
    return if latitude.blank? || longitude.blank?

    self.postal_code = EntourageServices::GeocodingService.get_postal_code(
      latitude,
      longitude
    )
  end

  def validate_uniqueness!
    return unless address.present?
    return unless Partner.same_as_partner(self).any?

    errors.add(:name, 'This partner already exists')
  end
end
