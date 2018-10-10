require 'experimental/jsonb_with_schema'
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
  include UpdatedAtSkippable
  include EntourageServices::LocationApproximationService::Callback
  include EntourageServices::GeocodingService::Callback
  include SensitiveWordsService::EntourageCallback
  include Experimental::AutoAccept::Joinable
  include Onboarding::V1::Entourage
  include Experimental::EntourageSlack::Callback

  ENTOURAGE_TYPES  = ['ask_for_help', 'contribution']
  ENTOURAGE_STATUS = ['open', 'closed', 'blacklisted']
  BLACKLIST_WORDS  = ['rue', 'avenue', 'boulevard', 'en face de', 'vend', 'loue', '06', '07', '01']
  CATEGORIES  = ['mat_help', 'non_mat_help', 'social']
  DISPLAY_CATEGORIES = ['social', 'event', 'mat_help', 'resource', 'info', 'skill', 'other']

  belongs_to :user
  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user
  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_many :conversation_messages, as: :messageable, dependent: :destroy
  has_many :moderator_reads, as: :moderatable, dependent: :destroy
  has_many :entourage_invitations, as: :invitable, dependent: :destroy
  has_one :entourage_score, dependent: :destroy
  has_one :moderation, class_name: 'EntourageModeration', autosave: true
  has_one :user_moderation, primary_key: :user_id, foreign_key: :user_id
  has_one :sensitive_words_check, as: :record, dependent: :destroy

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people
  validates_inclusion_of :status, in: ENTOURAGE_STATUS
  validates_inclusion_of :entourage_type, in: ENTOURAGE_TYPES
  validates_inclusion_of :category, in: CATEGORIES, allow_nil: true
  validates_inclusion_of :display_category, in: DISPLAY_CATEGORIES, allow_nil: true
  validates_uniqueness_of :uuid, on: :create
  validates_inclusion_of :community, in: Community.slugs
  validates_inclusion_of :group_type, in: -> (e) { e.community&.group_types&.keys || [] }
  validates_inclusion_of :public, in: -> (e) { e.public_accessibility_options }
  validates :metadata, schema: -> (e) { "#{e.group_type}:metadata" }

  scope :visible, -> { where.not(status: 'blacklisted') }
  scope :social_category, -> { where(category: 'social') }
  scope :mat_help_category, -> { where(category: 'mat_help') }
  scope :non_mat_help_category, -> { where(category: 'non_mat_help') }

  before_validation :set_community, on: :create
  before_validation :set_default_attributes, on: :create
  before_validation :generate_display_address

  after_create :check_moderation
  before_create :set_uuid

  def moderator_read_for(user:)
    moderator_reads.where(user_id: user.id).first
  end

  def self.with_moderator_reads_for(user:)
    joins(%(
      left join moderator_reads on (
        moderator_reads.user_id = #{user.id} and
        moderator_reads.moderatable_id = entourages.id and
        moderator_reads.moderatable_type = 'Entourage'
      )
    ))
  end

  def self.with_moderation
    joins("left join entourage_moderations on entourage_moderations.entourage_id = entourages.id")
  end

  def self.find_by_id_or_uuid identifier
    key =
      if !identifier.is_a?(String)
        :id
      elsif identifier.start_with?('1_hash_')
        :uuid_v2
      elsif identifier.length == 36
        :uuid
      elsif identifier.length == 12
        :uuid_v2
      else
        :id
      end

    @entourage = Entourage.visible.find_by!(key => identifier)
  end

  #An entourage can never be freezed
  def freezed?
    false
  end

  def approximated_location
    @approximated_location ||=
      EntourageServices::LocationApproximationService.new(self)
      .approximated_location
  end

  # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/attributes.rb
  attribute :community, Community::Type.new
  attribute :metadata, Experimental::JsonbWithSchema.new

  def metadata
    case group_type
    when 'private_circle'
      { visited_user_first_name: (title || "").gsub(/\ALes amis (de |d')/, '') }
    else
      super
    end
  end

  def group_type_config
    @group_type_config ||= community.group_types[group_type]
  end

  def public_accessibility_options
    case
    when group_type == 'outing'
      [true, false]
    when group_type == 'action' && entourage_type == 'contribution'
      [true, false]
    else
      [false]
    end
  end

  def has_outcome?
    group_type == 'action' && status == 'closed'
  end

  def outcome
    return unless has_outcome?
    {
      success: moderation.try(:action_outcome) == 'Oui'
    }
  end

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'private_circle:metadata'
        {
          visited_user_first_name: { type: :string }
        }
      when 'outing:metadata'
        {
          starts_at: { format: 'date-time-iso8601' },
          place_name: { type: :string },
          street_address: { type: :string },
          google_place_id: { type: :string },
          display_address: { type: :string }
        }
      end
    end
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

  def set_community
    return if user.nil?
    self.community = user.community
  end

  def set_default_attributes
    return if group_type.nil?
    case group_type
    when 'conversation'
      self.status         = :open
      self.title          = '(conversation)'
      self.entourage_type = :contribution
      self.latitude       = 0
      self.longitude      = 0
    end
  end

  def set_uuid
    self.uuid ||= SecureRandom.uuid
    self.uuid_v2 ||= self.class.generate_uuid_v2
    true
  end

  def self.generate_uuid_v2
    'e' + SecureRandom.urlsafe_base64(8)
  end

  def generate_display_address
    return unless group_type == 'outing' && (metadata_changed? || new_record?)
    address_fragments = metadata[:street_address].split(', ')
    if metadata[:place_name] != address_fragments.first
      address_fragments.unshift metadata[:place_name]
    end
    if address_fragments.last == 'France'
      address_fragments.pop
    end
    metadata[:display_address] = address_fragments.join(', ')
  rescue
    metadata[:display_address] = ""
  end

  private

  # If the record creation fails because of an non-unique uuid_v2,
  # generates a new uuid_v2 and retries (at most 3 times in total)
  def _create_record
    tries ||= 1
    transaction(requires_new: true) { super }
  rescue ActiveRecord::RecordNotUnique => e
    raise e unless /uuid_v2/ === e.cause.error
    logger.info "type=entourages.uuid_v2.not_unique tries=#{tries}"
    raise e if tries == 3
    self.uuid_v2 = nil
    set_uuid
    tries += 1
    retry
  end
end
