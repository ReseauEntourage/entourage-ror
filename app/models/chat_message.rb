class ChatMessage < ApplicationRecord
  include FeedsConcern
  include ChatServices::Spam
  include Deeplinkable
  include Translatable

  CONTENT_TYPES = %w(image/jpeg)
  BUCKET_PREFIX = "chat_messages"

  STATUSES = [:active, :updated, :deleted]

  has_ancestry

  scope :preload_comments_count, -> {
    select("chat_messages.*, count(comments.id) as comments_count")
    .joins(%(
      left outer join chat_messages as comments on
        comments.ancestry is not null and
        comments.ancestry::integer = chat_messages.id and
        comments.messageable_type = chat_messages.messageable_type and
        comments.messageable_id = chat_messages.messageable_id
    ))
    .group("chat_messages.id")
  }

  belongs_to :messageable, polymorphic: true
  belongs_to :entourage, -> {
    where("chat_messages.messageable_type = 'Entourage'")
  }, foreign_key: :messageable_id, optional: true # why optional? Cause it might belongs_to Tour
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

  def active?
    status.to_sym == :active
  end

  def updated?
    status.to_sym == :updated
  end

  def deleted?
    status.to_sym == :deleted
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
    @message_types ||= ['status_update', 'broadcast', *messageable&.group_type_config&.dig('message_types')]
  end

  def conversation_message_broadcast_id= id
    metadata[:conversation_message_broadcast_id] = id
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
    return if user.org_member?

    messageable.join_requests
      .where.not(user_id: user_id)
      .update_all(report_prompt_status: 'display')
  end
end
