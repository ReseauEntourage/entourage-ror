class SmsNotificationService
  def send_notification(phone_number, message, sms_type)
    unless ENV.key?('SMS_SENDER_NAME')
      Rails.logger.warn 'No SMS has been sent. Please provide SMS_SENDER_NAME environment variables'
      return
    end

    provider = ENV['SMS_PROVIDER']
    secondary_provider = ENV['SMS_PROVIDER_SECONDARY'].presence

    if secondary_provider != nil && sms_type == 'regenerate'
      number_of_deliveries = SmsDelivery.where(phone_number: phone_number, sms_type: sms_type).where("created_at > '#{Time.now - 60.minutes}'").count

      if number_of_deliveries.odd?
        provider = secondary_provider
      end
    end

    case provider
    when 'AWS'
      deliveryState = send_aws_sms(phone_number, message, sms_type)
    when 'Nexmo'
      deliveryState = send_nexmo_sms(phone_number, message, sms_type)
    when 'Slack'
      deliveryState = send_slack_message(phone_number, message, sms_type)
    when 'logs'
      deliveryState = debug_to_logs(phone_number, message, sms_type)
    else
      Rails.logger.warn 'No SMS has been sent. Please set SMS_PROVIDER to a valid value'
      return
    end

    SmsDelivery.create(phone_number: phone_number, status: deliveryState, sms_type: sms_type, provider: provider)
  end

  private
  def send_aws_sms(phone_number, message, sms_type)
    deliveryState='Ok'
    begin
      sns = Aws::SNS::Client.new({
        region: 'eu-west-1',
        credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
        })

      response = sns.publish({
        phone_number: phone_number,
        message: message,
        message_attributes: {
          'AWS.SNS.SMS.SenderID' => {string_value: ENV['SMS_SENDER_NAME'], data_type: 'String'},
          'AWS.SNS.SMS.SMSType' => {string_value: 'Transactional', data_type: 'String'},
        },
      })

      if response.message_id
        Rails.logger.info "Sent SMS to #{phone_number} provider=AWS response=#{response.inspect}"
      else
        Rails.logger.info "Error trying to send SMS to #{phone_number} provider=AWS response=#{response.inspect}"
        deliveryState='Provider Error'
      end
    rescue  => e
      Rails.logger.error "Error trying to send SMS to #{phone_number} provider=AWS error=#{e.message}"
      deliveryState='Sending Error'
    end
    return deliveryState
  end

  def send_nexmo_sms(phone_number, message, sms_type)
    deliveryState = 'Ok'
    begin
      nexmo = Nexmo::Client.new(
        api_key: ENV['NEXMO_API_KEY'],
        api_secret: ENV['NEXMO_API_SECRET']
      )

      response = nexmo.sms.send(
        to: phone_number,
        text: message,
        from: ENV['SMS_SENDER_NAME'],
      )

      Rails.logger.info "Sent SMS to #{phone_number} provider=Nexmo response=#{response.messages.first.to_h.to_json}"
    rescue Nexmo::Error => e
      Rails.logger.info "Error trying to send SMS to #{phone_number} provider=Nexmo response=#{e.message.inspect}"
      deliveryState='Provider Error'
    rescue  => e
      Rails.logger.error "Error trying to send SMS to #{phone_number} provider=Nexmo error=#{e.message.inspect}"
      deliveryState='Sending Error'
    end
    return deliveryState
  end

  def send_slack_message(phone_number, message, sms_type)
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    channel = '#test-env-sms'

    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: channel,
      username: ENV['SMS_SENDER_NAME'],
      icon_emoji: ':speech_balloon:',
      text: "À #{phone_number} (#{EnvironmentHelper.env})\n"\
            "```\n"\
            "#{message}"\
            '```'
    )

    return 'Ok'
  end

  def debug_to_logs(phone_number, message, sms_type)
    Rails.logger.debug "\nSMS to #{phone_number.inspect}: #{message.inspect}"
    return 'Ok'
  end
end
