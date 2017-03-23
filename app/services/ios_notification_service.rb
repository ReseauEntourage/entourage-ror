class IosNotificationService
  def send_notification(sender, object, content, badge, device_ids, extra={})
    return if device_ids.blank?

    #select * from join_requests as r inner join chat_messages as m on (m.messageable_id=r.joinable_id and m.messageable_type=r.joinable_type) where r.user_id=2 and r.status='accepted' and (r.last_message_read<m.updated_at OR r.last_message_read IS NULL)
    device_ids.each do |device_token|
      IosNotificationJob.perform_later(sender, object, content, badge, device_token, extra)
    end
  end
end