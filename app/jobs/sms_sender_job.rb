class SmsSenderJob
  #TODO: remove later. We use Sidekiq API to disable retries to debug user signup
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: :sms

  def perform(phone, message, sms_type)
    Rails.logger.info "SmsSenderJob (#{sms_type}) : sending #{message} to #{phone}"
    SmsNotificationService.new.send_notification(phone, message, sms_type)
  end

  #Activejob adapter
  def self.perform_later(phone, message, sms_type)
    SmsSenderJob.perform_async(phone, message, sms_type)
  end
end
