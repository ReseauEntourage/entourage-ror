class IosNotificationJob
  include Sidekiq::Worker

  sidekiq_options :timeout => 60

  def self.perform_later sender, object, content, device_token, community, extra={}, badge=nil
    IosNotificationJob.perform_async(sender, object, content, device_token, community, extra, badge)
  end

  def perform(sender, object, content, device_token, community, extra={}, badge=nil)
    return if device_token.blank?

    apps = Rpush::Apnsp8::App.where(name: community)

    if apps.blank?
      raise "No iOS notification has been sent: no '#{community}' certificate found."
    else
      apps.each do |app|
        begin
          notification = Rpush::Apnsp8::Notification.new
          notification.badge = badge if badge
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
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error e.message
        end
      end

      Rpush.push
    end
  end
end
