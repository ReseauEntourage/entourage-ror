class SmsNotificationService
  def send_notification(phone_number, message, sms_type)
    unless ENV.key?('SMS_SENDER_NAME')
      Rails.logger.warn 'No SMS has been sent. Please provide SMS_SENDER_NAME environment variables'
      return
    end

    case ENV['SMS_PROVIDER']
    when 'AWS'
      deliveryState = send_aws_sms(phone_number, message, sms_type)
    when 'Slack'
      deliveryState = send_slack_message(phone_number, message, sms_type)
    else
      Rails.logger.warn 'No SMS has been sent. Please set SMS_PROVIDER to a valid value'
      return
    end

    SmsDelivery.create(phone_number: phone_number, status: deliveryState, sms_type: sms_type)
  end

  private
  def send_aws_sms(phone_number, message, sms_type)
    deliveryState='Ok'
    begin
      sns = Aws::SNS::Client.new({
        region: 'eu-west-1',
        credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
        })

      sns.set_sms_attributes(attributes: { 'DefaultSenderID' => ENV['SMS_SENDER_NAME'],'DefaultSMSType' => 'Transactional'  })

      response = sns.publish({
        phone_number: phone_number,
        message: message
      })

      if response.message_id
        Rails.logger.info "Sent SMS to #{phone_number} response=#{response.inspect}"
      else
        Rails.logger.info "Error trying to send SMS to #{phone_number} response=#{response.inspect}"
        deliveryState='Provider Error'
      end
    rescue  => e
      Rails.logger.error "Error trying to send SMS to #{phone_number} error=#{e.message}"
      deliveryState='Sending Error'
    end
    return deliveryState
  end

  def send_slack_message(phone_number, message, sms_type)
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: '#test-env-sms',
      username: ENV['SMS_SENDER_NAME'],
      icon_emoji: ':speech_balloon:',
      text: "À #{phone_number}\n"\
            "```\n"\
            "#{message}"\
            "```"
    )

    return 'Ok'
  end
end
