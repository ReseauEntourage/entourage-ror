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

class Entourage < ApplicationRecord
  include FeedsConcern
  include UpdatedAtSkippable
  include EntourageServices::LocationApproximationService::Callback
  include EntourageServices::GeocodingService::Callback
  include SensitiveWordsService::EntourageCallback
  include Experimental::AutoAccept::Joinable
  include Onboarding::V1::Entourage
  include Experimental::EntourageSlack::Callback
  include ModerationServices::EntourageModeration::Callback

  ENTOURAGE_TYPES  = ['ask_for_help', 'contribution']
  ENTOURAGE_STATUS = ['open', 'closed', 'blacklisted', 'suspended']
  BLACKLIST_WORDS  = ['rue', 'avenue', 'boulevard', 'en face de', 'vend', 'loue', '06', '07', '01']
  CATEGORIES  = ['mat_help', 'non_mat_help', 'social']
  DISPLAY_CATEGORIES = ['social', 'event', 'mat_help', 'resource', 'info', 'skill', 'other']
  DEFAULT_EVENT_DURATION = 3.hours

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

  attr_accessor :current_join_request, :number_of_unread_messages

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people
  validates_inclusion_of :status, in: ENTOURAGE_STATUS
  validates_inclusion_of :entourage_type, in: ENTOURAGE_TYPES
  validates_inclusion_of :category, in: CATEGORIES, allow_nil: true
  validates_inclusion_of :display_category, in: DISPLAY_CATEGORIES, allow_nil: true
  validates_uniqueness_of :uuid, on: :create
  validates_inclusion_of :community, in: Community.slugs
  validates_inclusion_of :group_type, in: -> (e) { e.community&.group_types&.keys || [] }
  validates_inclusion_of :public, in: -> (e) { e.public_accessibility_options }
  validates_inclusion_of :online, in: -> (e) { e.online_setting_options }
  validates :metadata, schema: -> (e) { "#{e.group_type}:metadata" }
  validate :validate_outings_ends_at
  validates :image_url, format: { with: %r(\Ahttps?://\S+\z) }, allow_blank: true

  scope :visible, -> { where.not(status: ['blacklisted', 'suspended']) }
  scope :findable, -> { where.not(status: ['blacklisted']) }
  scope :social_category, -> { where(category: 'social') }
  scope :mat_help_category, -> { where(category: 'mat_help') }
  scope :non_mat_help_category, -> { where(category: 'non_mat_help') }
  scope :except_conversations, -> { where.not(group_type: :conversation) }
  scope :order_by_profile, -> (profile) {
    if profile == :ask_for_help
      order("case when entourage_type = 'contribution' then 1 else 2 end")
    else
      order("case when entourage_type = 'ask_for_help' then 1 else 2 end")
    end
  }
  scope :order_by_distance_from, -> (latitude, longitude) {
    if latitude && longitude
      order(PostgisHelper.distance_from(latitude, longitude))
    end
  }

  before_validation :set_community, on: :create
  before_validation :set_default_attributes, if: :group_type_changed?
  before_validation :set_outings_ends_at
  before_validation :set_outings_previous_at
  before_validation :set_outings_entourage_image_id
  before_validation :generate_display_address
  before_validation :reformat_content
  before_validation :set_default_online_attributes, if: :online_changed?

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

    @entourage = Entourage.findable.find_by!(key => identifier)
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

  # https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/attributes.rb#L114
  attribute :community, :community
  attribute :metadata, :jsonb_with_schema

  def group_type_config
    @group_type_config ||= community.group_types[group_type]
  end

  def public_accessibility_options
    case group_type
    when 'outing', 'action', 'group'
      [true, false]
    else
      [false]
    end
  end

  def online_setting_options
    case group_type
    when 'outing'
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
      when 'action:metadata', 'group:metadata'
        {
          city: { type: :string },
          display_address: { type: :string },
        }
      when 'private_circle:metadata'
        {
          visited_user_first_name: { type: :string },
          street_address: { type: :string },
          google_place_id: { type: :string },
        }
      when 'neighborhood:metadata'
        {
          address: { type: :string },
          google_place_id: { type: :string },
        }
      when 'outing:metadata'
        {
          starts_at: { format: 'date-time-iso8601' },
          ends_at: { format: 'date-time-iso8601' },
          previous_at: { format: 'date-time-iso8601' },
          place_name: { type: :string },
          street_address: { type: :string },
          google_place_id: { type: :string },
          display_address: { type: :string },
          entourage_image_id: { type: [:integer, :null] }
        }
      end
    end
  end

  def share_url
    return unless uuid_v2
    return if group_type == 'conversation'
    return community.store_short_url unless community.entourage?
    share_url_prefix = ENV['PUBLIC_SHARE_URL'] || "#{ENV['WEBSITE_APP_URL']}/actions/"
    "#{share_url_prefix}#{uuid_v2}"
  end

  def metadata= value
    value = add_metadata_schema_urn(value)
    super(value)
  end

  def group_type= value
    self.metadata = add_metadata_schema_urn(metadata)
    super(value)
  end

  def conversation?
    group_type == 'conversation'
  end

  def add_metadata_schema_urn(value)
    value = {} if value.nil?
    value['$id'] = "urn:entourage:#{group_type}:metadata" if group_type
    value
  end

  def metadata_datetimes_formatted
    formats =
      if metadata[:ends_at].midnight == metadata[:starts_at].midnight
        ["%A %-d %B de %H:%M ", "à %H:%M"]
      else
        ["%A %-d %B à %H:%M — ", "%A %-d %B à %H:%M"]
      end
    [I18n.l(metadata[:starts_at], format: formats[0]),
     I18n.l(metadata[:ends_at],   format: formats[1])].join
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
    when 'action', 'group'
      self.metadata = {
        city: ''
      }
    end
  end

  def set_outings_ends_at
    return unless group_type == 'outing'
    return unless metadata_changed?
    return unless metadata
    return unless metadata[:starts_at].present?
    return unless metadata[:ends_at].nil?

    ends_at = self.metadata[:starts_at] + DEFAULT_EVENT_DURATION rescue nil
    self.metadata[:ends_at] = ends_at if ends_at
  end

  def set_outings_previous_at
    return unless group_type == 'outing'
    return unless metadata_changed?
    return unless metadata
    return unless metadata[:previous_at].nil?
    self.metadata[:previous_at] = nil
  end

  def set_outings_entourage_image_id
    return unless group_type == 'outing'
    return unless metadata_changed?
    return unless metadata
    return unless metadata[:entourage_image_id].nil?
    self.metadata[:entourage_image_id] = nil
  end

  def validate_outings_ends_at
    return unless group_type == 'outing'
    return unless metadata[:starts_at].present?
    return unless metadata[:ends_at].present?

    if metadata[:ends_at] < metadata[:starts_at]
      errors.add(:metadata, "'ends_at' must not be before 'starts_at'")
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
    return unless (metadata_changed? || new_record?)
    case group_type
    when 'action', 'group'
      generate_action_display_address
    when 'outing'
      generate_outing_display_address
    end
  end

  def generate_action_display_address
    return unless group_type.in?(['action', 'group'])
    if metadata[:city].present? && postal_code.present?
      metadata[:display_address] = "#{metadata[:city]} (#{postal_code})"
    else
      metadata[:display_address] = ""
    end
  end

  def generate_outing_display_address
    return unless group_type == 'outing'
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

  def reformat_content(force: false)
    self.title = title&.squish&.sub(/\S/, &:upcase) if force || title_changed?
    self.description = description&.strip if force || description_changed?
  end

  def set_default_online_attributes
    if online?
      metadata.merge!(
        place_name:      "Visioconférence en ligne",
        street_address:  "Visioconférence en ligne",
        display_address: "Visioconférence en ligne",
        google_place_id: "_online_"
      )
      self.latitude = 0
      self.longitude = 0
    else
      self.event_url = nil
    end
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
