class IosNotificationService
  def send_notification(sender, object, content, device_ids, community, extra={}, badge=nil)
    return if device_ids.blank?
    device_ids.each do |device_token|
      IosNotificationJob.perform_later(sender, object, content, device_token, community, extra, badge)
    end
  end

  def unregister_token(device_token)
    Rails.logger.info "type=rpush.on.apns_feedback device_token=#{device_token}"
    UserApplication.where(push_token: device_token, device_family: UserApplication::IOS).destroy_all()
  end
end
