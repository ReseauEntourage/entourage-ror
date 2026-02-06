class SlackQuestionJob < ApplicationJob
  queue_as :default

  def perform(channel:, ts:, text:, user:)
    # Use the Jules analyzer to generate an answer
    answer = SlackServices::JulesAnalyzer.new(text: text).answer

    # Post the answer back to Slack in the same thread
    send_to_slack(channel: channel, ts: ts, text: answer)
  end

  private

  def send_to_slack(channel:, ts:, text:)
    token = ENV['SLACK_BOT_TOKEN']
    return if token.blank?

    HTTParty.post("https://slack.com/api/chat.postMessage",
      body: {
        channel: channel,
        thread_ts: ts,
        text: text
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{token}"
      }
    )
  end
end
