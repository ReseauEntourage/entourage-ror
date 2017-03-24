class IosNotificationService
  def send_notification(sender, object, content, device_ids, extra={}, badge=nil)
    return if device_ids.blank?
    IosNotificationJob.perform_later(sender, object, content, device_ids, extra, badge)
  end
end