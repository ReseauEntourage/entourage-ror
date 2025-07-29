module IraiserWebhookService
  def self.handle_notification headers, params
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: '@Grégoire',
      username: 'iRaiser Webhook',
      icon_emoji: ':bell:',
      text: "headers:\n"\
            "```\n"\
            "#{headers.inspect}\n"\
            "```\n"\
            "\n"\
            "params:\n"\
            "```\n"\
            "#{params}\n"\
            "```\n"
    )
  end
end
