class Partner < ApplicationRecord
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

  before_save :reformat_url, if: :website_url_changed?
  before_save :reformat_needs, if: :needs_changed?
  before_save :geocode, if: :address_changed?
  after_commit :sync_poi

  geocoded_by :address

  attr_accessor :following # see api/v1/partners#show

  scope :staff, -> { where(staff: true).ordered }
  scope :no_staff, -> { where(staff: false).ordered }
  scope :ordered, -> { order(:name) }

  PLACEHOLDER_URL = 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/partner-placeholder.png'.freeze

  def large_logo_url
    super.presence || PLACEHOLDER_URL
  end

  CHECKMARK_URL = 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png'.freeze
  STAFF_BADGE_URL = 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/entourage-logo-small.png'.freeze

  def small_logo_url
    super.presence || (staff ? STAFF_BADGE_URL : CHECKMARK_URL)
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

  private

  def needs_changed?
    donations_needs_changed? || volunteers_needs_changed?
  end

end
