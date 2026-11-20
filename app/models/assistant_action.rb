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

  scope :succeeded, -> { where(status: SUCCEEDED) }

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
