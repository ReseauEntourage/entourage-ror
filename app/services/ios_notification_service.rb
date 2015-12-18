class IosNotificationService
  def initialize(notification_pusher = nil)
    @notification_pusher = notification_pusher
  end
  
  def send_notification(sender, object, content, device_ids)
    entourage = Rpush::Apns::App.where(name: 'entourage').first

    if entourage.nil?
      raise 'No IOS notification has been sent. Please save a Rpush::Apns::App in database'
    else
      device_ids.each do |device_token|
        notification = Rpush::Apns::Notification.new
        notification.app = entourage
        notification.device_token = device_token
        notification.alert = "Entourage vous envoi un message"
        notification.data = { sender: sender, object: object, content: content }
        notification.save
      end
      notification_pusher.push
    end
  end
  
  private
  
  def notification_pusher
    @notification_pusher ||= Rpush
  end
end