module JoinRequestAcceptTracking
  extend ActiveSupport::Concern

  included do
    after_initialize { reset_accept_tracking }
    before_save :track_accept
    after_save :reset_accept_tracking
  end

  private

  def track_accept
    return unless new_record? || status_changed?

    timestamps_to_update = []

    case status
    when 'pending'
      timestamps_to_update.push :requested_at
      self.accepted_at = nil
    when 'accepted'
      timestamps_to_update.push :accepted_at
    end

    @accept_tracking_timestamp_attributes_for_update = timestamps_to_update
  end

  def timestamp_attributes_for_update
    super + @accept_tracking_timestamp_attributes_for_update
  end

  def reset_accept_tracking
    @accept_tracking_timestamp_attributes_for_update = []
  end
end
