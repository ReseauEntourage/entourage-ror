require 'json'

class OpenaiRequestJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :openai_assistants

  def perform openai_assistant_id
    openai_assistant = OpenaiAssistant.find(openai_assistant_id)

    return unless instance = openai_assistant.instance

    MatchingServices::Connect.new(instance: instance).perform do |on|
      on.success do |response|
        openai_assistant.update_columns(
          openai_assistant_id: response.metadata[:assistant_id],
          openai_thread_id: response.metadata[:thread_id],
          openai_run_id: response.metadata[:run_id],
          openai_message_id: response.metadata[:message_id],
          status: nil,
          run_ends_at: Time.current,
          updated_at: Time.current
        )

        response.each_recommandation do |matching, score, explanation, index|
          instance.matchings.build(match: matching, score: score, explanation: explanation, position: index)
        end

        instance.save(validate: false)
      end

      on.failure do |error|
        openai_assistant.update_columns(
          status: :error,
          run_ends_at: Time.current,
          updated_at: Time.current
        )
      end
    end
  end

  def self.perform_later openai_assistant_id
    OpenaiRequestJob.perform_async(openai_assistant_id)
  end
end
