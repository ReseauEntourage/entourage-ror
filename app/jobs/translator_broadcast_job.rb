require 'sidekiq/api'

class TranslatorBroadcastJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :default

  RETRY_DURATION = 10.seconds

  def perform conversation_message_broadcast_id
    # reschedule whenever the queue is not empty for this broadcast
    if ConversationMessageBroadcastJob.count_jobs_for(conversation_message_broadcast_id)
      return TranslatorBroadcastJob.perform_in(RETRY_DURATION, conversation_message_broadcast_id)
    end

    translate!(conversation_message_broadcast_id)
  end

  def translate! conversation_message_broadcast_id
    chat_message_ids = ChatMessage.with_broadcast_id(conversation_message_broadcast_id).pluck(:id)

    puts "-- -- chat_message_ids.any?: #{chat_message_ids.any?}"

    return unless chat_message_ids.any?

    translation = nil

    chat_message_ids.each do |chat_message_id|
      chat_message = ChatMessage.find(chat_message_id)

      if translation
        puts "-- copy"
        chat_message.translate_from_copy!(translation)
      else
        puts "-- translate!"
        translation = chat_message.translate!
      end
    end
  end

  # ActiveJob interface
  def self.perform_later conversation_message_broadcast_id
    perform_async conversation_message_broadcast_id
  end
end
