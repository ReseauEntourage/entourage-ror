class AndroidNotificationJob < ActiveJob::Base
  def perform(sender, object, content, device_ids, extra={},badge=nil)
    return if device_ids.blank?

    entourage = Rpush::Gcm::App.where(name: 'entourage').first

    if entourage.nil?
      raise 'No android notification has been sent. Please save a Rpush::Gcm::App in database'
    else
      notification = Rpush::Gcm::Notification.new
      notification.badge = badge if badge
      notification.app = entourage
      notification.registration_ids = device_ids
      notification.data = { sender: sender, object: object, content: {message: content, extra: extra} }
      notification.save!

      Rpush.push unless Rails.env.test?
    end
  end
end