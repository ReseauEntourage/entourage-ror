class ChatMessage < ApplicationRecord
  include FeedsConcern
  include ChatServices::Spam
  include ChatServices::PrivateConversation
  include Deeplinkable
  include Mentionable
  include Offensable
  include Translatable
  include Reactionnable
  include Surveyable

  CONTENT_TYPES = %w(image/jpeg)
  BUCKET_PREFIX = "chat_messages"

  STATUSES = [:active, :updated, :deleted, :offensible, :offensive]

  store_attribute :options, :auto_post_type, :string
  store_attribute :options, :auto_post_id, :integer

  has_ancestry

  belongs_to :messageable, polymorphic: true
  belongs_to :entourage, -> {
    where("chat_messages.messageable_type = 'Entourage'")
  }, foreign_key: :messageable_id, optional: true # why optional? Cause it might belongs_to Neighborhood
  belongs_to :user
  belongs_to :deleter, class_name: :User, required: false

  before_validation :generate_content

  validates :messageable_id, :messageable_type, :user_id, presence: true
  validates :content, presence: true, unless: -> (m) { m.image_url.present? || m.deleted? }
  validates_inclusion_of :message_type, in: -> (m) { m.message_types }
  validates :metadata, schema: -> (m) { "#{m.message_type}:metadata" }

  validate :validate_ancestry!
  validate :validate_private_conversation_is_not_blocked!

  scope :ordered, -> { order("created_at DESC") }
  scope :with_content, -> { where("content <> ''") }
  scope :no_deleted_without_comments, -> { where("(status != 'deleted' or comments_count > 0)") }

  attribute :metadata, :jsonb_with_schema

  after_create do |message|
    unless message.message_type == 'status_update'
      FeedUpdatedAt.update(
        message.messageable_type,
        message.messageable_id,
        message.created_at
      )
    end
  end

  after_create :update_sender_report_prompt_status
  after_create :update_recipients_report_prompt_status

  after_commit :update_parent_comments_count
  after_save :touch_messageable_timestamp

  alias_attribute :name, :content

  class << self
    def bucket
      Storage::Client.images
    end

    def presigned_url key, content_type
      bucket.object(path key).presigned_url(
        :put,
        expires_in: 1.minute.to_i,
        acl: 'public-read',
        content_type: content_type,
        cache_control: "max-age=#{365.days}"
      )
    end

    def url_for key
      bucket.url_for(key: path(key), extra: { expire: 1.day })
    end

    def url_for_with_size key, size
      bucket.public_url_with_size(key: path(key), size: size)
    end

    def path key
      "#{BUCKET_PREFIX}/#{key}"
    end
  end

  class << self
    def interpolate message:, user:, author: nil
      first_name = UserPresenter.format_first_name(user.first_name)

      if message.match?(/\{\{\s*interlocutor\s*\}\}/)
        author ||= ModerationServices.moderation_area_for_user_with_default(user)&.interlocutor_for_user(user)
      end

      message
        .gsub(/\{\{\s*first_name\s*\}\}/, first_name.to_s)
        .gsub(/\{\{\s*email\s*\}\}/, user.email.to_s)
        .gsub(/\{\{\s*phone\s*\}\}/, user.phone.to_s)
        .gsub(/\{\{\s*city\s*\}\}/, user.city.to_s)
        .gsub(/\{\{\s*uuid\s*\}\}/, user.uuid.to_s)
        .gsub(/\{\{\s*default_neighborhood\s*\}\}/, user.default_neighborhood&.name.to_s)
        .gsub(/\{\{\s*interests\s*\}\}/, user.interest_i18n.sort.join(', '))
        .gsub(/\{\{\s*involvements\s*\}\}/, user.involvement_i18n.sort.join(', '))
        .gsub(/\{\{\s*availability\s*\}\}/, user.availability_formatted.to_s)
        .gsub(/\{\{\s*interlocutor\s*\}\}/, author&.first_name.to_s)
    end
  end

  def active?
    status.to_sym == :active
  end

  def updated?
    status.to_sym == :updated
  end

  def deleted?
    status.to_sym == :deleted
  end

  def offensible?
    status.to_sym == :offensible
  end

  def offensive?
    status.to_sym == :offensive
  end

  def visible?
    active? || updated?
  end

  # @param force true to bypass deletion
  def content force = false
    return "" if deleted? && !force

    self[:content]
  end

  # @param force true to bypass deletion
  def image_url force = false
    return if deleted? && !force

    self[:image_url]
  end

  def image_path force = false
    return unless image_url(force).present?

    ChatMessage.url_for(image_url(force))
  end

  def image_url_with_size size, force = false
    return unless image_url(force).present?

    ChatMessage.url_for_with_size(image_url(force), size)
  end

  def validate_ancestry!
    if parent && parent.has_parent?
      errors.add(:interests, "Il n'est pas possible de commenter une discussion")
    end
  end

  def validate_private_conversation_is_not_blocked!
    return unless messageable
    return unless messageable.is_a?(Entourage)
    return unless messageable.conversation?
    return unless messageable.member_ids.any?

    if UserBlockedUser.with_users(messageable.member_ids).any?
      errors.add(:status, "La conversation a été bloquée par l'un des participants")
    end
  end

  def neighborhood?
    messageable_type == 'Neighborhood'
  end

  def entourage?
    messageable_type == 'Entourage'
  end

  def entourage_id
    nil unless entourage?
    messageable_id
  end

  def self.joins_group_join_requests
    joins(%(
      join join_requests on joinable_id   = messageable_id
                        and joinable_type = messageable_type
    ))
  end

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'outing:metadata'
        {
          operation: { type: :string, enum: [:created, :updated, :cancelled] },
          title: { type: :string },
          starts_at: { format: 'date-time-iso8601' },
          display_address: { type: :string },
          uuid: { type: :string }
        }
      when 'status_update:metadata'
        {
          status: { type: :string },
          outcome_success: { type: [:boolean, :null] }
        }
      when 'share:metadata'
        {
          type: { type: :string, enum: [:entourage, :poi] },
          uuid: { type: :string }
        }
      when 'broadcast:metadata'
        {
          conversation_message_broadcast_id: { type: :integer }
        }
      end
    end
  end

  def message_types
    @message_types ||= ['auto', 'status_update', 'broadcast', *messageable&.group_type_config&.dig('message_types')]
  end

  def content= text
    # filter unexpected html tags from content
    self[:content] = Mentionable.filter_html_tags(text)
  end

  def conversation_message_broadcast_id= id
    metadata[:conversation_message_broadcast_id] = id
  end

  def recipient_ids
    return siblings.pluck(:user_id).uniq + [parent.user_id] - [user_id] if parent && parent.present?

    messageable.accepted_member_ids.uniq - [user_id]
  end

  private

  def generate_content
    self.content = generated_content
  rescue => e
    errors.add(:content, e.message)
  end

  def generated_content
    case message_type
    when 'outing' then outing_content
    when 'status_update' then status_update_content
    when 'share' then share_content
    else content
    end
  end

  def outing_content
    action = {
      created: 'a créé',
      updated: 'a modifié'
    }[metadata[:operation].to_sym]

    starts_at = Time.zone.parse(metadata[:starts_at])
    [
      "#{action} un évènement :",
      metadata[:title],
      I18n.l(starts_at, format: "le %d/%m à %Hh%M,"),
      metadata[:display_address]
    ].join("\n")
  end

  def status_update_content
    op = {
      closed: "a clôturé",
      open: "a rouvert",
      user_deleted: "a clôturé",
      user_blocked: "a clôturé",
      user_anonymized: "a clôturé",
      cancelled: "a annulé"
    }[metadata[:status].to_sym]

    "#{op} #{GroupService.name messageable, :l}#{[' : ', content].join if content.present?}"
  end

  def share_content
    case metadata[:type]
    when 'entourage'
      group = Entourage.find_by(uuid_v2: metadata[:uuid])
      [group.title, group.share_url].map(&:strip).map(&:presence).compact.join("\n")
    when 'poi'
      poi = Poi.find_by(id: metadata[:uuid])
      [poi.name, poi.adress].map(&:strip).map(&:presence).compact.join("\n")
    else
      nil
    end
  end

  def update_parent_comments_count
    return unless ancestry.present?

    parent.update(comments_count: parent.children
      .where(status: :active)
      .where(messageable_type: messageable_type)
      .where(messageable_id: messageable_id)
      .count
    )
  end

  def touch_messageable_timestamp
    return unless messageable.present?
    return unless messageable.respond_to?(:updated_at)

    messageable.update_column(:updated_at, Time.current)
  end

  def update_sender_report_prompt_status
    JoinRequest.where(
      joinable_type: messageable_type,
      joinable_id: messageable_id,
      user_id: user_id,
      report_prompt_status: 'display'
    )
    .update_all(report_prompt_status: 'dismissed')
  end

  def update_recipients_report_prompt_status
    return if messageable.group_type != 'conversation'
    return if ChatMessage.where(messageable: messageable).where("id < ?", id).exists?

    return if user.moderator?
    return if user.ambassador?
    return if user.association?

    messageable.join_requests
      .where.not(user_id: user_id)
      .update_all(report_prompt_status: 'display')
  end
end
