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

      if extra[:type].in?(['JOIN_REQUEST_ACCEPTED', 'ENTOURAGE_INVITATION', 'INVITATION_STATUS'])
        # the Android app displays the sender as title, we want the group title
        sender = object
      end

      notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
      NotificationTruncationService.truncate_message! notification
      notification.save!
    end
  end
end