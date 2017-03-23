class PushNotificationService
  def initialize(android_notification_service = nil, ios_notification_service = nil)
    @android_notification_service = android_notification_service
    @ios_notification_service = ios_notification_service
  end

  def send_notification(sender, object, content, users, extra={})
    Rails.logger.info("Sending push notif to users : #{users.map(&:email)}, content: #{content}, sender: #{sender}, object: #{object}")
    users.each do |user|
      token = UserServices::UserApplications.new(user: user).android_app.try(:push_token)
      android_notification_service.send_notification(sender, object, content, token, extra, badge(user))
    end

    users.each do |user|
      token = UserServices::UserApplications.new(user: user).ios_app.try(:push_token)
      ios_notification_service.send_notification(sender, object, content, token, extra, badge(user))
    end
  end
  
  private

  def badge(user)
    UserServices::UnreadMessages.new(user: user).number_of_unread_messages
  end
  
  def android_notification_service
    @android_notification_service || AndroidNotificationService.new
  end
  
  def ios_notification_service
    @ios_notification_service || IosNotificationService.new
  end
end
