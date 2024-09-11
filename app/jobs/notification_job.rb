class NotificationJob
  include Sidekiq::Worker

  sidekiq_options :timeout => 60

  def self.perform_later sender, object, content, device_token, community, extra={}, badge=nil
    NotificationJob.perform_async(sender, object, content, device_token, community, extra)
  end

  def perform sender, object, content, device_token, community, extra={}
    return if device_token.blank?
    return unless user_application = UserApplication.find_by_push_token(device_token)

    if user_application.android?
      perform_android(sender, object, content, device_token, community, extra)
    elsif user_application.ios?
      perform_ios(sender, object, content, device_token, community, extra)
    end
  end

  def perform_android sender, object, content, device_token, community, extra={}
    app = Rpush::Fcm::App.where(name: community).first

    if app.nil?
      raise "No Android notification has been sent: no '#{community}' certificate found."
    else
      notification = Rpush::Fcm::Notification.new
      notification.app = app
      notification.device_token = device_token
      notification.notification = {
        title: object || sender,
        body: content
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

  def perform_ios sender, object, content, device_token, community, extra={}
    app = Rpush::Apnsp8::App.where(name: community).first

    if app.nil?
      raise "No Android notification has been sent: no '#{community}' certificate found."
    else
      notification = Rpush::Apnsp8::Notification.new
      notification.app = app
      notification.device_token = device_token.to_s
      notification.alert = if sender.present?
        {
          title: sender,
          subtitle: object,
          body: content
        }
      else
        {
          title: object,
          body: content
        }
      end

      notification.data = { sender: sender, object: object, content: { message: content, extra: extra } }
      notification.save!
    end
  end
end
