class ConversationMessageBroadcastJob < ActiveJob::Base
  queue_as :default

  def perform(conversation_message_broadcast_id:, sender_id:, recipient_ids:, content:)
    conversation_message_broadcast = ConversationMessageBroadcast.find(conversation_message_broadcast_id)
    conversation_message_broadcast.update_attribute(:status, :sending)

    sender = User.find(sender_id)
    recipients = User.find(recipient_ids)

    ChatServices::ChatMessageBuilder.create_broadcast(sender: sender, recipients: recipients, content: content) do |success_users, failure_users|
      conversation_message_broadcast.update_attribute(:status, :archived)
    end
  end
end
