require 'sidekiq/api'

class ChatMessagesJob
  include Sidekiq::Worker
  sidekiq_options :retry => false, queue: :default

  # @caution we must perform as many jobs as the number of messages we have to create
  # performs the creation of a message from the sender to a specific recipient
  def perform(sender_id, recipient_id, content)
    user = User.find(sender_id)
    conversation = ChatServices::ChatMessageBuilder.find_conversation(recipient_id, user_id: sender_id)

    join_request = if conversation.new_record?
      conversation.join_requests.to_a.find { |r| r.user_id == sender_id }
    else
      user.join_requests.accepted.find_by!(joinable: conversation)
    end

    ChatServices::ChatMessageBuilder.new(
      user: user,
      joinable: conversation,
      join_request: join_request,
      params: {
        message_type: :text,
        content: content,
      }
    ).create
  end

  # ActiveJob interface
  def self.perform_later(sender_id, user_ids, content)
    user_ids.each do |recipient_id|
      perform_async(sender_id, recipient_id, content)
    end
  end
end
