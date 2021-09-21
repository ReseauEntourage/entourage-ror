require 'sidekiq/api'

class ConversationMessageBroadcastDenormJob
  include Sidekiq::Worker
  sidekiq_options :retry => false, queue: :denorm

  def perform(conversation_message_broadcast_id, sender_id, recipient_id, content)
    conversation_message_broadcast = ConversationMessageBroadcast.find(conversation_message_broadcast_id)
    conversation_message_broadcast.update_attributes(
      sent_users_count: conversation_message_broadcast.sent.count
    )
  end

  # ActiveJob interface
  def self.perform_later conversation_message_broadcast_id
    perform_async conversation_message_broadcast_id
  end
end
