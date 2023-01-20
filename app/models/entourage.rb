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
  include CoordinatesScopable
  include JoinableScopable
  include ModeratorReadable

  after_validation :track_status_change

  ENTOURAGE_TYPES  = ['ask_for_help', 'contribution']
  ENTOURAGE_STATUS = ['open', 'closed', 'blacklisted', 'suspended']
  OUTING_STATUS = ['open', 'closed', 'blacklisted', 'suspended', 'full', 'cancelled']
  BLACKLIST_WORDS  = ['rue', 'avenue', 'boulevard', 'en face de', 'vend', 'loue', '06', '07', '01']
  CATEGORIES  = ['mat_help', 'non_mat_help', 'social']
  DISPLAY_CATEGORIES = ['social', 'resource', 'mat_help', 'other']
  DEPRECATED_DISPLAY_CATEGORIES = ['info', 'skill', 'event']
  DEFAULT_EVENT_DURATION = 3.hours

  belongs_to :user
  has_many :neighborhoods_entourages, dependent: :destroy
  has_many :neighborhoods, through: :neighborhoods_entourages
  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_one :last_chat_message, -> {
    select('DISTINCT ON (messageable_id, messageable_type) *').order('messageable_id, messageable_type, created_at desc')
  }, as: :messageable, class_name: 'ChatMessage'
  has_one :chat_messages_count, -> {
    select('DISTINCT ON (messageable_id, messageable_type) COUNT(*), messageable_id, messageable_type').group('messageable_id, messageable_type')
  }, as: :messageable, class_name: 'ChatMessage'
  has_many :conversation_messages, as: :messageable, dependent: :destroy
  has_many :parent_conversation_messages, -> { where(ancestry: nil) }, as: :messageable, dependent: :destroy, class_name: :ConversationMessage
  has_many :entourage_invitations, foreign_key: :invitable_id, dependent: :destroy

  has_one :entourage_score, dependent: :destroy
  has_one :moderation, class_name: 'EntourageModeration', autosave: true
  has_one :user_moderation, primary_key: :user_id, foreign_key: :user_id
  has_one :sensitive_words_check, as: :record, dependent: :destroy

  attr_accessor :current_join_request, :number_of_unread_messages, :entourage_image_id
  attr_accessor :change_ownership_message
  attr_accessor :user_status
  attr_accessor :cancellation_message
  attr_accessor :entourage_image_id

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people

  validates_inclusion_of :status, in: OUTING_STATUS, if: :outing?
  validates_inclusion_of :status, in: ENTOURAGE_STATUS, unless: :outing?
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

  scope :active, -> { where(status: ['open', 'full']) }
  scope :visible, -> { where.not(status: ['blacklisted', 'suspended']) }
  scope :findable, -> { where.not(status: ['blacklisted']) }
  scope :social_category, -> { where(category: 'social') }
  scope :mat_help_category, -> { where(category: 'mat_help') }
  scope :non_mat_help_category, -> { where(category: 'non_mat_help') }
  scope :action, -> { where(group_type: :action) }
  scope :contributions, -> { where(entourage_type: :contribution) }
  scope :ask_for_helps, -> { where(entourage_type: :ask_for_help) }
  scope :except_conversations, -> { where.not(group_type: :conversation) }
  scope :order_by_profile, -> (profile) {
    if profile == :ask_for_help
      order("case when entourage_type = 'contribution' then 1 else 2 end")
    else
      order("case when entourage_type = 'ask_for_help' then 1 else 2 end")
    end
  }
  scope :like, -> (search) {
    return unless search.present?

    where('(unaccent(title) ilike unaccent(:title) or unaccent(description) ilike unaccent(:description))', {
      title: "%#{search.strip}%",
      description: "%#{search.strip}%"
    })
  }
  scope :moderator_search, -> (search) {
    return if search == 'any'
    return where(entourage_moderations: { moderator_id: nil }) if search == 'none'
    return where(entourage_moderations: { moderator_id: search.to_i }) if search.present?
  }

  before_validation :set_community, on: :create
  before_validation :set_default_attributes, if: :group_type_changed?
  before_validation :set_outings_ends_at
  before_validation :set_outings_previous_at
  before_validation :set_outings_image_urls
  before_validation :set_outings_place_limit
  before_validation :generate_display_address
  before_validation :reformat_content
  before_validation :set_default_online_attributes, if: :online_changed?

  after_create :check_moderation
  before_create :set_uuid

  after_update :create_chat_message_on_status_update, if: :saved_change_to_status?

  def create_from_join_requests!
    ApplicationRecord.connection.transaction do
      participations = self.join_requests.to_a

      self.join_requests = []
      self.chat_messages = []
      self.instance_variable_set(:@readonly, false)

      # we set the uuid manually instead of updating it gradually at each
      # join_request. see next comment.
      self.uuid_v2 = ConversationService.hash_for_participants(participations.map(&:user_id), validated: false)
      self.save!

      participations.each do |join_request|
        join_request.joinable = self

        # if we update the UUID at each user, one of the intermediary
        # conversations (e.g. first user with itself) may already exist
        # and cause an error.
        join_request.skip_conversation_uuid_update!
        join_request.save!
      end
    end
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
    # we want to define required fields
    return JsonSchemaService.base do
      {
        city: { type: :string },
        display_address: { type: :string },
        close_message: { type: [:string, :null] },
      }
    end.merge({ required: [:city, :display_address]}) if urn == 'action:metadata'

    JsonSchemaService.base do
      case urn
      when 'group:metadata'
        {
          city: { type: :string },
          display_address: { type: :string },
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
          landscape_url: { type: [:string, :null] },
          landscape_thumbnail_url: { type: [:string, :null] },
          portrait_url: { type: [:string, :null] },
          portrait_thumbnail_url: { type: [:string, :null] },
          place_limit: { type: [:string, :integer, :null] }
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
    value = format_metadata_image_paths(value)

    super(value)
  end

  def group_type= value
    self.metadata = add_metadata_schema_urn(metadata)
    super(value)
  end

  def image_path
    return unless action?
    return unless contribution?

    becomes(Contribution).image_path
  end

  def entourage_image_id= entourage_image_id
    return unless outing?

    if entourage_image = EntourageImage.find_by_id(entourage_image_id)
      self.metadata[:landscape_url] = entourage_image[:landscape_url]
      self.metadata[:landscape_thumbnail_url] = entourage_image[:landscape_thumbnail_url]
      self.metadata[:portrait_url] = entourage_image[:portrait_url]
      self.metadata[:portrait_thumbnail_url] = entourage_image[:portrait_thumbnail_url]
    else
      remove_entourage_image_id!
    end

    @entourage_image_id = entourage_image_id
  end

  def remove_entourage_image_id!
    self.metadata[:landscape_url] = nil
    self.metadata[:landscape_thumbnail_url] = nil
    self.metadata[:portrait_url] = nil
    self.metadata[:portrait_thumbnail_url] = nil
  end

  # whenever a mobile user creates an outing with an entourage_image, this image has an absolute url path
  # we need to convert this absolute path to a relative one. Example:
  # https://[server-name].com/entourage_images/images/my-image.png?AMZ_args should be stored as entourage_images/images/my-image.png
  def format_metadata_image_paths metadata
    return metadata unless outing?

    metadata.map do |key, value|
      if value && [:landscape_url, :landscape_thumbnail_url, :portrait_url, :portrait_thumbnail_url].include?(key.to_sym)
        [key, EntourageImage.from_absolute_to_relative_url(value)]
      else
        [key, value]
      end
    end.to_h
  end

  def starts_at
    return unless outing?
    return unless metadata
    metadata[:starts_at]
  end

  def ends_at
    return unless outing?
    return unless metadata
    metadata[:ends_at]
  end

  def outing_image_url?
    return unless outing?

    (self.metadata[:landscape_thumbnail_url] || self.metadata[:landscape_url]).present?
  end

  def outing_image_url
    return unless outing?
    return unless self.metadata[:landscape_thumbnail_url] || self.metadata[:landscape_url]

    EntourageImage.storage.url_for(key: self.metadata[:landscape_thumbnail_url] || self.metadata[:landscape_url])
  end

  def status_list
    return OUTING_STATUS if outing?

    ENTOURAGE_STATUS
  end

  def conversation?
    group_type && group_type.to_sym == :conversation
  end

  def action?
    group_type && group_type.to_sym == :action
  end

  def outing?
    group_type && group_type.to_sym == :outing
  end

  def recurrent?
    outing? && recurrency_identifier.present?
  end

  def contribution?
    entourage_type && entourage_type.to_sym == :contribution
  end

  def cancelled?
    status && status.to_sym == :cancelled
  end

  def closed?
    status && status.to_sym == :closed
  end

  def ongoing?
    status && [:open, :full].include?(status.to_sym)
  end

  def future_outing?
    outing? && starts_at > Time.zone.now
  end

  def add_metadata_schema_urn(value)
    value = {} if value.nil?
    value['$id'] = "urn:entourage:#{group_type}:metadata" if group_type
    value
  end

  def metadata_datetimes_formatted
    formats =
      if metadata[:ends_at].midnight == metadata[:starts_at].midnight
        ["%A %-d %B %Y de %H:%M ", "à %H:%M"]
      else
        ["%A %-d %B %Y à %H:%M — ", "%A %-d %B %Y à %H:%M"]
      end
    [I18n.l(metadata[:starts_at], format: formats[0]),
     I18n.l(metadata[:ends_at],   format: formats[1])].join
  end

  def metadata_with_image_paths size = :medium
    return metadata unless outing?

    metadata.map do |key, value|
      if value.present? && [:landscape_url, :portrait_url].include?(key)
        [key, EntourageImage.storage.public_url_with_size(key: value, size: size)]
      elsif value.present? && [:landscape_thumbnail_url].include?(key)
        [key, EntourageImage.storage.public_url_with_size(key: "landscape_url", size: size)]
      elsif value.present? && [:portrait_thumbnail_url].include?(key)
        [key, EntourageImage.storage.public_url_with_size(key: "portrait_url", size: size)]
      else
        [key, value]
      end
    end.to_h
  end

  def close_entourage_from_user_status! user_status
    @user_status = user_status

    update_attribute(:status, :closed)
  end

  def interlocutor_of user
    return unless conversation?

    members.find do |member|
      member.id != user.id
    end
  end

  protected

  def check_moderation
    return unless description.present?
    ping_slack if is_description_unacceptable?
  end

  def create_chat_message_on_status_update
    return unless saved_change_to_status?
    return unless status.in?(['closed', 'open'])

    outcome = if status == 'closed' && moderation&.saved_change_to_action_outcome?
      {
        'Oui' => true,
        'Non' => false,
      }[moderation.action_outcome]
    else
      nil
    end

    chat_message_status = status
    content = nil

    if @user_status.present? && status == 'closed'
      chat_message_status = "user_#{@user_status}"
      content = I18n.t('community.chat_messages.status_update.closed_user')
    end

    ChatMessage.create(
      messageable: self,
      user_id: user_id,
      content: content,
      message_type: :status_update,
      metadata: {
        status: chat_message_status,
        outcome_success: outcome
      }
    )
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
      # why no public = false?
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

  def set_outings_image_urls
    return unless group_type == 'outing'
    return unless metadata_changed?
    return unless metadata

    if metadata[:landscape_url].nil?
      self.metadata[:landscape_url] = nil
    end

    if metadata[:portrait_url].nil?
      self.metadata[:portrait_url] = nil
    end

    if metadata[:landscape_thumbnail_url].nil?
      self.metadata[:landscape_thumbnail_url] = nil
    end

    if metadata[:portrait_thumbnail_url].nil?
      self.metadata[:portrait_thumbnail_url] = nil
    end
  end

  def set_outings_place_limit
    return unless outing?
    return unless metadata[:place_limit].nil?
    self.metadata[:place_limit] = nil
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

  def track_status_change
    self[:status_changed_at] = Time.zone.now if status_changed?
  end
end
