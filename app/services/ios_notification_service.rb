class IosNotificationService
  def send_notification(sender, object, content, device_id, community, extra={}, badge=nil)
    return if device_id.blank?
    IosNotificationJob.perform_later(sender, object, content, device_id, community, extra, badge)
  end

  def unregister_token(device_token)
    Rails.logger.info "IOS Notification : Unregistering device_token=#{device_token}"
    UserApplication.where(push_token: device_token, device_family: UserApplication::IOS).destroy_all()
  end
end
