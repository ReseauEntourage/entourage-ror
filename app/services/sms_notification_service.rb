class SmsNotificationService
  def initialize(notification_pusher = nil)
    @notification_pusher = notification_pusher
  end
  
  def send_notification(phone_number, message)
    if (ENV.key?('SINCH_API_KEY') && ENV.key?('SINCH_API_SECRET'))
      notification_pusher.send(ENV['SINCH_API_KEY'], ENV['SINCH_API_SECRET'], message, phone_number)
      Rails.logger.info "Sent SMS to #{phone_number}"
    else
      Rails.logger.warn 'No SMS has been sent. Please provide SINCH_API_KEY and SINCH_API_SECRET environment variables'
    end
  end
  
  private
  
  def notification_pusher
    @notification_pusher ||= SinchSms
  end
end