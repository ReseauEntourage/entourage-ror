class PushNotificationService
  def initialize(android_notification_service = nil, ios_notification_service = nil)
    @android_notification_service = android_notification_service
    @ios_notification_service = ios_notification_service
  end
  
  def send_notification(sender, object, content, users)
    android_device_ids = users.where(device_type: User.device_types[:android]).where.not(device_id: nil).pluck(:device_id)
    android_notification_service.send_notification sender, object, content, android_device_ids
    
    ios_device_ids = users.where(device_type: User.device_types[:ios]).where.not(device_id: nil).pluck(:device_id)
    ios_notification_service.send_notification sender, object, content, ios_device_ids
  end
  
  private
  
  def android_notification_service
    @android_notification_service || AndroidNotificationService.new
  end
  
  def ios_notification_service
    @ios_notification_service || IosNotificationService.new
  end
end
