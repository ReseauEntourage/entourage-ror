class PushNotificationService
  def initialize(android_notification_service)
    @android_notification_service = android_notification_service
  end
  
  def send_notification(sender, object, content, users)
    android_device_ids = users.where(device_type: 'android').where.not(device_id: nil).pluck(:device_id)
    android_notification_service.send_notification sender, object, content, android_device_ids
  end
  
  private
  
  def android_notification_service
    return @android_notification_service || AndroidNotificationService.new
  end
end