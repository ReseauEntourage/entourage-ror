class AndroidNotificationService
  def update_canonical_id(old_id, canonical_id)
    ua = UserApplication.find_by(push_token: old_id)
    if ua != nil
      ua.update(push_token: canonical_id)
      Rails.logger.info "ANDROID Notification: updating  old_id=#{old_id} to canonical_id=#{canonical_id}"
    else
      Rails.logger.error "ERROR type=rpush.gcm_canonical_id old_id=#{old_id} canonical_id=#{canonical_id}: unknown user ID"
    end
  end

  def unregister_token(registration_id)
    Rails.logger.info "ANDROID Notification: unregistering registration_id=#{registration_id}"
    UserApplication.where(push_token: registration_id, device_family: UserApplication::ANDROID).destroy_all()
  end
end
