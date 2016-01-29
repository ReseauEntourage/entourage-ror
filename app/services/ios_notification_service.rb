class IosNotificationService
  def send_notification(sender, object, content, device_ids)
    return if device_ids.blank?
    device_ids.each do |device_token|
      IosNotificationJob.perform_later(sender, object, content, device_token)
    end
  end
end