class PushNotificationService
  def initialize(android_notification_service = nil, ios_notification_service = nil)
    @android_notification_service = android_notification_service
    @ios_notification_service = ios_notification_service
  end

  def send_notification(sender, object, content, users, extra={})
    Rails.logger.info("Sending push notif to users : #{users.map(&:email)}, content: #{content}, sender: #{sender}, object: #{object}")
    badge = JoinRequest.joins("inner join chat_messages on (chat_messages.messageable_id=join_requests.joinable_id and chat_messages.messageable_type=join_requests .joinable_type and (join_requests.last_message_read<chat_messages.updated_at OR join_requests.last_message_read IS NULL))")
                .where(user: sender, status: 'accepted').count

    android_device_ids = users.map { |user| UserServices::UserApplications.new(user: user).android_app.try(:push_token) }.compact
    android_notification_service.send_notification(sender, object, content, android_device_ids, extra)

    ios_device_ids = users.map { |user| UserServices::UserApplications.new(user: user).ios_app.try(:push_token) }.compact
    ios_notification_service.send_notification(sender, object, content, badge, ios_device_ids, extra)
  end
  
  private
  
  def android_notification_service
    @android_notification_service || AndroidNotificationService.new
  end
  
  def ios_notification_service
    @ios_notification_service || IosNotificationService.new
  end
end
