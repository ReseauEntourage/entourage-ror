class DigestEmail < ApplicationRecord
  validates :status, inclusion: { in: ['scheduled', 'delivering', 'delivered'] }

  include CustomTimestampAttributesForUpdate
  before_save :track_status_change

  scope :scheduled, -> { where(status: :scheduled) }
  scope :sorted, -> { order(deliver_at: :asc) }
  scope :past_delivery, -> { where("deliver_at <= now()") }
  scope :upcoming_delivery, -> { where("deliver_at >= now()") }
  scope :to_deliver, -> { scheduled.past_delivery }

  private

  def track_status_change
    if status_changed? && !status_changed_at_changed?
      @custom_timestamp_attributes_for_update = ["status_changed_at"]
    end
  end
end
