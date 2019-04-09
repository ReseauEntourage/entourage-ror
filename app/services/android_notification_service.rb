class AndroidNotificationService
  def send_notification(sender, object, content, device_ids, community, extra={}, badge=nil)
    return if device_ids.blank?
    AndroidNotificationJob.perform_later(sender, object, content, device_ids, community, extra, badge)
  end

  def update_canonical_id(old_id, canonical_id)
    ua = UserApplication.find_by(push_token: old_id)
    if ua != nil
      ua.update_attributes(push_token: canonical_id)
      Rails.logger.info "type=rpush.gcm_canonical_id old_id=#{old_id} canonical_id=#{canonical_id}"
    else
      Rails.logger.error "ERROR type=rpush.gcm_canonical_id old_id=#{old_id} canonical_id=#{canonical_id}: unknown ID"
    end
  end

  def unregister_token(registration_id)
    Rails.logger.info "type=rpush.gcm_invalid_registration_id registration_id=#{registration_id}"
    UserApplication.where(push_token: registration_id, device_family: UserApplication::ANDROID).destroy_all()
  end
end
