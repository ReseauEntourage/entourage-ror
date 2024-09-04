require 'json'

class OpenaiAssistantJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :openai_assistants

  def perform openai_assistant_id
    openai_assistant = OpenaiAssistant.find(openai_assistant_id)

    return unless instance = openai_assistant.instance

    EntourageServices::Matcher.new(instance: instance).find_best_matches do |on|
      on.success do |matches|
        openai_assistant.update_columns(
          openai_assistant_id: matches['assistant_id'],
          openai_thread_id: matches['thread_id'],
          openai_run_id: matches['run_id'],
          openai_message_id: matches['message_id'],
          status: matches['status'],
          run_ends_at: Time.current,
          updated_at: Time.current
        )

        matches['matchings'].each_with_index do |matching, index|
          next unless parse_matching = EntourageServices::Matcher.parse_matching(matching)

          instance.matchings.build(match: parse_matching, score: matching['score'], position: index)
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
    OpenaiAssistantJob.perform_async(openai_assistant_id)
  end
end
