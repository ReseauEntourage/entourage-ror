class SmsSenderJob
  #TODO: remove later. We use Sidekiq API to disable retries to debug user signup
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(phone, message)
    SmsNotificationService.new.send_notification(phone, message)
  end

  #Activejob adapter
  def self.perform_later(phone, message)
    SmsSenderJob.perform_async(phone, message)
  end
end