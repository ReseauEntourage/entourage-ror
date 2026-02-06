require 'sidekiq/api'

class CodeQuestionJob
  include Sidekiq::Worker

  def perform question, channel, thread_ts
    response = GeminiServices::CodeAnalyzer.new(question).analyze

    answer = response[:success] ? response[:answer] : response[:error]

    OpenaiServices::CodeQuestion.new.send_to_slack(
      answer,
      channel: channel,
      thread_ts: thread_ts
    )
  end

  def self.perform_later question, channel, thread_ts
    perform_async(question, channel, thread_ts)
  end
end
