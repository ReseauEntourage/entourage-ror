class AndroidNotificationJob
  include Sidekiq::Worker

  sidekiq_options :timeout => 60

  def self.perform_later sender, object, content, device_ids, community, extra={}, badge=nil
    AndroidNotificationJob.perform_async(sender, object, content, device_ids, community, extra, badge)
  end

  def perform(sender, object, content, device_ids, community, extra={}, badge=nil)
    return if device_ids.blank?

    app = Rpush::Gcm::App.where(name: community).first

    if app.nil?
      raise "No Android notification has been sent: no '#{community}' certificate found."
    else
      notification = Rpush::Gcm::Notification.new
      #notification.badge = badge if badge
      notification.app = app
      notification.registration_ids = device_ids
      # the Android app displays the sender as title
      notification.data = { sender: object || sender, object: object, content: {message: content, extra: extra} }

      NotificationTruncationService.truncate_message! notification

      notification.save!
    end
  end
end
