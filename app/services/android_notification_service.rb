class AndroidNotificationService
  def send_notification(sender, object, content, device_ids, community, extra={}, badge=nil)
    return if device_ids.blank?
    AndroidNotificationJob.perform_later(sender, object, content, device_ids, community, extra, badge)
  end
end
