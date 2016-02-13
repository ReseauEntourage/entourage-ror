class SmsSenderJob < ActiveJob::Base
  def perform(phone, message)
    SmsNotificationService.new.send_notification(phone, message)
  end
end