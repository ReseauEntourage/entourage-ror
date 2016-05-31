class PushNotificationService
  def initialize(android_notification_service = nil, ios_notification_service = nil)
    @android_notification_service = android_notification_service
    @ios_notification_service = ios_notification_service
  end


  def send_notification(sender, object, content, users, extra={})
    Rails.logger.info("Sending push notif to users : #{users.map(&:email)}, content: #{content}")
    android_device_ids = users.map { |user| UserServices::UserApplications.new(user: user).android_app.try(:push_token) }.compact
    android_notification_service.send_notification(sender, object, content, android_device_ids, extra)

    ios_device_ids = users.map { |user| UserServices::UserApplications.new(user: user).ios_app.try(:push_token) }.compact
    ios_notification_service.send_notification(sender, object, content, ios_device_ids, extra)
  end
  
  private
  
  def android_notification_service
    @android_notification_service || AndroidNotificationService.new
  end
  
  def ios_notification_service
    @ios_notification_service || IosNotificationService.new
  end
end
