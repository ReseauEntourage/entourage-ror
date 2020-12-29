class ConversationMessageBroadcastJob
  include Sidekiq::Worker

  def perform(conversation_message_broadcast_id, sender_id, recipient_ids, content)
    conversation_message_broadcast = ConversationMessageBroadcast.find(conversation_message_broadcast_id)
    conversation_message_broadcast.update_attribute(:status, :sending)

    sender = User.find(sender_id)
    recipients = User.find(recipient_ids)

    ChatServices::ChatMessageBuilder.create_broadcast(
      conversation_message_broadcast: conversation_message_broadcast,
      sender: sender,
      recipients: recipients,
      content: content
    ) do |success_users, failure_users|
      conversation_message_broadcast.update_attribute(:status, :sent)
    end
  end

  # ActiveJob interface
  def self.perform_later(conversation_message_broadcast_id, sender_id, recipient_ids, content)
    perform_async(conversation_message_broadcast_id, sender_id, recipient_ids, content)
  end
end
