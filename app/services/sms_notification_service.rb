class SmsNotificationService
  def initialize(notification_pusher = nil)
    @notification_pusher = notification_pusher
  end
  
  def send_notification(phone_number, message)
    unless ENV.key?('SINCH_API_KEY') && ENV.key?('SINCH_API_SECRET')
      Rails.logger.warn 'No SMS has been sent. Please provide SINCH_API_KEY and SINCH_API_SECRET environment variables'
      return
    end

    response = notification_pusher.send(ENV['SINCH_API_KEY'], ENV['SINCH_API_SECRET'], message, phone_number)

    if !response.is_a?(Hash) || response.key?('errorCode')
      Rails.logger.info "Error trying to send SMS to #{phone_number} response=#{response.inspect}"
    else
      Rails.logger.info "Sent SMS to #{phone_number} response=#{response.inspect}"
    end
  end
  
  private
  
  def notification_pusher
    @notification_pusher ||= SinchSms
  end
end