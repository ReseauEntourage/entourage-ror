class PushNotificationService
  def initialize(android_notification_service = nil, ios_notification_service = nil)
    @android_notification_service = android_notification_service
    @ios_notification_service = ios_notification_service
  end

  def send_notification(sender, object, content, users, extra={})
    Rails.logger.info("Sending push notif to users : #{users.map(&:email)}, content: #{content}, sender: #{sender}, object: #{object}")
    users.each do |user|
      android_tokens = UserServices::UserApplications.new(user: user).android_app_tokens
      android_tokens.each do |token|
        android_notification_service.send_notification(sender, object, content, token.push_token, user.community.slug, extra, badge(user))
      end
      ios_tokens = UserServices::UserApplications.new(user: user).ios_app_tokens
      ios_tokens.each do |token|
        ios_notification_service.send_notification(sender, object, content, token.push_token, user.community.slug, extra, badge(user))
      end
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
