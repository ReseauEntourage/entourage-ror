class IosNotificationJob < ActiveJob::Base
  def perform(sender, object, content, device_token, extra={})
    return if device_token.blank?

    puts "device token = #{device_token}"

    entourage = Rpush::Apns::App.where(name: 'entourage').first

    if entourage.nil?
      raise 'No IOS notification has been sent. Please save a Rpush::Apns::App in database'
    else
      notification = Rpush::Apns::Notification.new
      notification.app = entourage
      notification.device_token = device_token.to_s
      notification.alert = "Entourage vous envoi un message"
      notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
      notification.save!

      Rpush.push unless Rails.env.test?
    end
  end
end