class IosNotificationService
  def send_notification(sender, object, content, device_ids, community, extra={}, badge=nil)
    return if device_ids.blank?
    device_ids.each do |device_token|
      IosNotificationJob.perform_later(sender, object, content, device_token, community, extra, badge)
    end
  end
end
