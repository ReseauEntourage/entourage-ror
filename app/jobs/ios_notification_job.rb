class IosNotificationJob < ApplicationJob
  def perform(sender, object, content, device_token, community, extra={},badge=nil)
    return if device_token.blank?

    apps = Rpush::Apns::App.where(name: community)

    if apps.blank?
      raise "No iOS notification has been sent: no '#{community}' certificate found."
    else
      apps.each do |app|
        begin
          notification = Rpush::Apns::Notification.new
          notification.badge = badge if badge
          notification.app = app
          notification.device_token = device_token.to_s
          notification.alert = if sender.present?
            {
              title: sender,
              subtitle: object,
              body: content
            }
          else
            {
              title: object,
              body: content
            }
          end

          notification.data = { sender: sender, object: object, content: { message: content, extra: extra } }
          notification.save!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error e.message
        end
      end
    end
  end
end
