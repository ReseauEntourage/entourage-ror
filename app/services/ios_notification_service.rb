class IosNotificationService
  def initialize(notification_pusher = nil)
    @notification_pusher = notification_pusher
  end
  
  def send_notification(sender, object, content, device_ids)
    Rails.logger.warn 'No IOS notification has been sent. Please save a Rpush::Apns::App in database'.red
  end
  
  private
  
  def notification_pusher
    @notification_pusher ||= Rpush
  end
end