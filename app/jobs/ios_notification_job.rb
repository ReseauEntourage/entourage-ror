class IosNotificationJob < ActiveJob::Base
  def perform(sender, object, content, device_token, extra={},badge=nil)
    return if device_token.blank?

    puts "device token = #{device_token}"

    entourage = Rpush::Apns::App.where(name: 'entourage').first

    if entourage.nil?
      raise 'No IOS notification has been sent. Please save a Rpush::Apns::App in database'
    else
      begin
        notification = Rpush::Apns::Notification.new
        #notification.badge = badge if badge
        notification.app = entourage
        notification.device_token = device_token.to_s
        notification.alert = content
        notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
        notification.save!

        Rpush.push unless Rails.env.test?
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
      end
    end
  end
end