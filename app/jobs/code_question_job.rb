require 'sidekiq/api'

class CodeQuestionJob
  include Sidekiq::Worker

  def perform question, channel, thread_ts
    response = ClaudeServices::CodeAnalyzer.new(question).analyze

    OpenaiServices::CodeQuestion.new.send_to_slack(
      response[:answer],
      channel: channel,
      thread_ts: thread_ts
    )
  end

  def self.perform_later question, channel, thread_ts
    perform_async(question, channel, thread_ts)
  end
end
