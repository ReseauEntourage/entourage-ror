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
      notification.device_token = device_token
      notification.notification = {
        title: object || sender,
        body: object
      }.transform_values(&:to_s)

      notification.data = {
        content: {
          message: content,
          extra: extra
        }.to_json
      }

      NotificationTruncationService.truncate_message! notification

      notification.save!
    end
  end
end
