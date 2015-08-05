class AndroidNotificationService
  def initialize(notification_pusher = nil)
    @notification_pusher = notification_pusher
  end
  
  def send_notification(sender, object, content, device_ids)
    notification = Rpush::Gcm::Notification.new
    notification.app = Rpush::Gcm::App.find_by_name('entourage')
    notification.registration_ids = device_ids
    notification.data = { sender: sender, object: object, content: content }
    notification.save!
    
    @notification_pusher.push
  end
  
  private
  
  def notification_pusher
    notification_pusher ||= Rpush
  end
end