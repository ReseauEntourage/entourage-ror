class AndroidNotificationService
  def send_notification(sender, object, content, device_ids, extra={})
    return if device_ids.blank?
    AndroidNotificationJob.perform_later(sender, object, content, device_ids, extra)
  end
end