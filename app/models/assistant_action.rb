# An action that the AI assistant asked Local to run on behalf of a user (see
# Assistant::ActionRunner). It is what makes the action idempotent and traceable.
#
# `result` only ever holds identifiers and statuses, never the text of a message or of a
# publication: the row is kept as long as the account exists and deleted with it.
class AssistantAction < ApplicationRecord
  PROCESSING = 'processing'.freeze
  SUCCEEDED = 'succeeded'.freeze
  FAILED = 'failed'.freeze
  STATUSES = [PROCESSING, SUCCEEDED, FAILED].freeze

  belongs_to :user
  belongs_to :subject, polymorphic: true, optional: true

  validates :idempotency_key, :action_type, :request_digest, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :idempotency_key, uniqueness: { scope: :user_id }

  FIRST_MESSAGE_TYPES = %w[member.first_message outing.notify_organizer].freeze

  scope :succeeded, -> { where(status: SUCCEEDED) }

  # The number of first messages that the assistant sent in the name of a user, for the follow-up of
  # the team: the messages that started a conversation. Counted from the actions rather than
  # stored on the user, so that it goes with the rows when the account is deleted.
  def self.first_messages_count user
    succeeded
      .where(user_id: user.id, action_type: FIRST_MESSAGE_TYPES)
      .where("result->'body'->>'firstMessage' = 'true'")
      .count
  end

  def processing?
    status == PROCESSING
  end

  def succeeded?
    status == SUCCEEDED
  end

  def failed?
    status == FAILED
  end
end
