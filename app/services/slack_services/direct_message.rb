module SlackServices
  # Sends a Slack DM to a specific user, unlike SlackServices::Notifier which only posts
  # to internal team channels via incoming webhooks. Requires the Slack Web API
  # (chat.postMessage) with a user token (ENV['SLACK_DM_USER_TOKEN'], scope chat:write) tied
  # to a real Slack member (e.g. a dedicated service account) rather than a bot token -
  # Slack always files bot-authored DMs under "Apps" in the client sidebar, whereas a
  # user token makes the message appear as a normal person-to-person DM. The user's own
  # slack_id (their workspace member id, cf. User#slack_id) is used as the `channel`
  # parameter, which is how the Web API addresses a DM.
  class DirectMessage
    include HTTParty
    base_uri 'https://slack.com/api'

    def initialize(user:, text:)
      @user = user
      @text = text
    end

    def send!
      return false if user.blank? || user.slack_id.blank?
      return false if ENV['SLACK_DM_USER_TOKEN'].blank?

      response = self.class.post(
        '/chat.postMessage',
        headers: {
          'Authorization' => "Bearer #{ENV['SLACK_DM_USER_TOKEN']}",
          'Content-Type' => 'application/json'
        },
        body: { channel: user.slack_id, text: text }.to_json
      )

      response.success? && response.parsed_response['ok'] == true
    rescue => e
      Sentry.capture_exception(e)
      false
    end

    private

    attr_reader :user, :text
  end
end
