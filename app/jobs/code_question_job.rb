require 'sidekiq/api'

class CodeQuestionJob
  include Sidekiq::Worker

  def perform question
    chunks = OpenaiServices::CodeSearchService.new.search(question: question)
    answer = OpenaiServices::CodeQuestion.new.answer(question: question, code_chunks: chunks)

    OpenaiServices::CodeQuestion.new.send_to_slack(
      answer,
      channel: params.dig(:event, :channel),
      thread_ts: params.dig(:event, :ts)
    )
  end

  def self.perform_later question
    perform_async(question)
  end
end
