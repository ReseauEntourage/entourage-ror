class IosNotificationJob < ActiveJob::Base
  def perform(sender, object, content, badge, device_token, extra={})
    return if device_token.blank?

    entourage = Rpush::Apns::App.where(name: 'entourage').first

    if entourage.nil?
      raise 'No IOS notification has been sent. Please save a Rpush::Apns::App in database'
    else
      begin
        notification = Rpush::Apns::Notification.new
        notification.app = entourage
        notification.device_token = device_token.to_s
        notification.alert = content
        notification.badge = badge
        notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
        notification.save!

        Rpush.push unless Rails.env.test?
      rescue ActiveRecord::RecordInvalid => e
        puts "IosNotificationJob.perform using device token = #{device_token}"
        Rails.logger.error e.message
      end
    end
  end
end