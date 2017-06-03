# == Schema Information
#
# Table name: entourages
#
#  id               :integer          not null, primary key
#  status           :string           default("open"), not null
#  title            :string           not null
#  entourage_type   :string           not null
#  user_id          :integer          not null
#  latitude         :float            not null
#  longitude        :float            not null
#  number_of_people :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  description      :string
#

class Entourage < ActiveRecord::Base
  include FeedsConcern

  ENTOURAGE_TYPES  = ['ask_for_help', 'contribution']
  ENTOURAGE_STATUS = ['open', 'closed', 'blacklisted']
  BLACKLIST_WORDS  = ['rue', 'avenue', 'boulevard', 'en face de', 'vend', 'loue', '06', '07', '01']
  CATEGORIES  = ['mat_help', 'non_mat_help', 'social']

  belongs_to :user
  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user
  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_many :entourage_invitations, as: :invitable, dependent: :destroy

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people
  validates_inclusion_of :status, in: ENTOURAGE_STATUS
  validates_inclusion_of :entourage_type, in: ENTOURAGE_TYPES
  validates_inclusion_of :category, in: CATEGORIES, allow_nil: true
  validates_uniqueness_of :uuid, on: :create

  scope :visible, -> { where.not(status: 'blacklisted') }
  scope :social_category, -> { where(category: 'social') }
  scope :mat_help_category, -> { where(category: 'mat_help') }
  scope :non_mat_help_category, -> { where(category: 'non_mat_help') }

  after_create :check_moderation
  before_create :set_uuid

  #An entourage can never be freezed
  def freezed?
    false
  end

  def approximated_location
   location ||= Geocoder.search([latitude, longitude]).first
   return '' unless location
   "#{location.city}, #{location.postal_code}"
  end

  protected

  def check_moderation
    return unless description.present?
    ping_slack if is_description_unacceptable?
  end

  def is_description_unacceptable?
    BLACKLIST_WORDS.any? { |bad_word| description.include? bad_word }
  end

  def ping_slack
    return unless ENV['ENTOURAGES_MODERATION_WEBHOOK_URL']

    notifier = Slack::Notifier.new(ENV['ENTOURAGES_MODERATION_WEBHOOK_URL'],
                                   http_options: { open_timeout: 5 })
    admin_entourage_url = Rails.application
                               .routes
                               .url_helpers
                               .admin_entourage_url(id, host: ENV['ADMIN_HOST'])
    notifier.ping "Un nouvel entourage doit être modéré : #{admin_entourage_url}", http_options: { open_timeout: 10 }
  end

  def set_uuid
    uuid = SecureRandom.uuid
    true
  end
end
