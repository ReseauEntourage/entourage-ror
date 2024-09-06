class IosNotificationService
  def unregister_token(device_token)
    Rails.logger.info "IOS Notification : Unregistering device_token=#{device_token}"
    UserApplication.where(push_token: device_token, device_family: UserApplication::IOS).destroy_all()
  end
end
