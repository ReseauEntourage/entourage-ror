class AndroidNotificationJob < ActiveJob::Base
  def perform(sender, object, content, device_ids, community, extra={},badge=nil)
    return if device_ids.blank?

    app = Rpush::Gcm::App.where(name: community).first

    if app.nil?
      raise "No Android notification has been sent: no '#{community}' certificate found."
    else
      notification = Rpush::Gcm::Notification.new
      #notification.badge = badge if badge
      notification.app = app
      notification.registration_ids = device_ids
      notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
      notification.save!
    end
  end
end