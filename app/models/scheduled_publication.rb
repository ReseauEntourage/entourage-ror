class ScheduledPublication < ApplicationRecord
  STATUSES = [:pending, :published, :cancelled, :failed]

  belongs_to :publishable, polymorphic: true
  belongs_to :neighborhood, optional: true
  belongs_to :author, class_name: 'User'

  validates :scheduled_at, presence: true
  validates_inclusion_of :status, in: STATUSES.map(&:to_s)

  scope :pending, -> { where(status: :pending) }
  scope :published, -> { where(status: :published) }
  scope :cancelled, -> { where(status: :cancelled) }
  scope :failed, -> { where(status: :failed) }
  scope :of_type, -> (publishable_type) { where(publishable_type: publishable_type) }

  # @caution NeighborhoodMessageBroadcast/UserMessageBroadcast share the conversation_message_broadcasts
  # table without a Rails `type` column: Rails' polymorphic association therefore stores/loads them
  # under their base_class name, not the concrete subclass - cast explicitly to get the real behavior
  def publishable
    return ConversationMessageBroadcast.find_with_cast(publishable_id) if broadcast?

    super
  end

  def post?
    publishable_type == 'ChatMessage'
  end

  def broadcast?
    publishable_type == 'ConversationMessageBroadcast'
  end

  def pending?
    status == 'pending'
  end

  def in_the_past?
    scheduled_at.present? && scheduled_at <= Time.zone.now
  end
end
