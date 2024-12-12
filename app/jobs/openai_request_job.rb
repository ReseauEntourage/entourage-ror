require 'json'

class OpenaiRequestJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :openai_requests

  def perform openai_request_id
    openai_request = OpenaiRequest.find(openai_request_id)

    return unless instance = openai_request.instance

    MatchingServices::Connect.new(instance: instance).perform do |on|
      on.success do |response|
        openai_request.update_columns(
          error: nil,
          response: response.to_json,
          openai_assistant_id: response.metadata[:assistant_id],
          openai_thread_id: response.metadata[:thread_id],
          openai_run_id: response.metadata[:run_id],
          openai_message_id: response.metadata[:message_id],
          status: :success,
          run_ends_at: Time.current,
          updated_at: Time.current
        )

        response.each_recommandation do |matching, score, explanation, index|
          instance.matchings.build(match: matching, score: score, explanation: explanation, position: index)
        end

        instance.save(validate: false)
      end

      on.failure do |error, response|
        openai_request.update_columns(
          error: error,
          response: response.to_json,
          status: :error,
          run_ends_at: Time.current,
          updated_at: Time.current
        )
      end
    end
  end

  def self.perform_later openai_request_id
    OpenaiRequestJob.perform_async(openai_request_id)
  end
end
