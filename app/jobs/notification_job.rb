class NotificationJob
  include Sidekiq::Worker

  sidekiq_options :timeout => 60

  def self.perform_later sender, object, content, device_token, community, extra={}, badge=nil
    NotificationJob.perform_async(sender, object, content, device_token, community, extra, badge)
  end

  def perform(sender, object, content, device_token, community, extra={}, badge=nil)
    return if device_token.blank?

    app = Rpush::Fcm::App.where(name: community).first

    if app.nil?
      raise "No Android notification has been sent: no '#{community}' certificate found."
    else
      notification = Rpush::Fcm::Notification.new
      notification.app = app
      notification.device_token = device_ids
      notification.data = { sender: object || sender, object: object, content: {message: content, extra: extra} }.transform_values(&:to_s)

      NotificationTruncationService.truncate_message! notification

      notification.save!
    end
  end
end
