require 'sidekiq/api'

class ConversationMessageBroadcastDenormJob
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: :denorm

  def perform conversation_message_broadcast_id
    conversation_message_broadcast = ConversationMessageBroadcast.find_with_cast(conversation_message_broadcast_id)
    conversation_message_broadcast.update(
      sent_recipients_count: conversation_message_broadcast.sent.count
    )

    # reschedule whenever the queue is not empty for this broadcast
    if ConversationMessageBroadcastJob.count_jobs_for(conversation_message_broadcast_id)
      return ConversationMessageBroadcastDenormJob.perform_later(conversation_message_broadcast_id)
    end
  end

  # ActiveJob interface
  def self.perform_later conversation_message_broadcast_id
    perform_async conversation_message_broadcast_id
  end
end
