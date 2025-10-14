module JoinRequestAcceptTracking
  extend ActiveSupport::Concern

  included do
    include CustomTimestampAttributesForUpdate
    before_save :track_accept
  end

  private

  def track_accept
    return unless new_record? || status_changed?

    timestamps_to_update = []

    case status
    when 'pending'
      timestamps_to_update.push('requested_at')
      self.accepted_at = nil
    when 'accepted'
      timestamps_to_update.push('accepted_at')
    end

    @custom_timestamp_attributes_for_update = timestamps_to_update
  end
end
