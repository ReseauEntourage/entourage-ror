require 'sidekiq/api'

class ConversationMessageBroadcastJob
  include Sidekiq::Worker
  sidekiq_options :retry => false, queue: :broadcast

  # @caution we must perform as many jobs as the number of messages we have to create
  # performs the creation of a message from the sender to a specific recipient
  def perform(conversation_message_broadcast_id, sender_id, recipient_id, content)
    user = User.find(sender_id)
    conversation_message_broadcast = ConversationMessageBroadcast.find(conversation_message_broadcast_id)
    conversation = ChatServices::ChatMessageBuilder.find_conversation(recipient_id, user_id: sender_id)

    join_request = if conversation.new_record?
      conversation.join_requests.to_a.find { |r| r.user_id == sender_id }
    else
      user.join_requests.accepted.find_by!(joinable: conversation)
    end

    chat_builder = ChatServices::ChatMessageBuilder.new(
      user: user,
      joinable: conversation,
      join_request: join_request,
      params: {
        message_type: :broadcast,
        conversation_message_broadcast_id: conversation_message_broadcast.id,
        content: content,
      }
    )

    chat_builder.create do |on|
      on.success do |message|
        join_request.update_column(:last_message_read, message.created_at)

        ApplicationRecord.transaction do
          conversation_message_broadcast.update_attributes(
            sent_users_count: (ConversationMessageBroadcast.find(conversation_message_broadcast_id).sent_users_count || 0) + 1
          )
        end
      end
    end
  end

  # ActiveJob interface
  def self.perform_later(conversation_message_broadcast_id, sender_id, content)
    user_ids_to_broadcast(conversation_message_broadcast_id, sender_id).each do |recipient_id|
      set(
        tags: [conversation_message_broadcast_id]
      ).perform_async(conversation_message_broadcast_id, sender_id, recipient_id, content)
    end

    ConversationMessageBroadcastDenormJob.perform_later conversation_message_broadcast_id
  end

  def self.jobs
    Sidekiq::Queue.new('broadcast')
  end

  def self.count_jobs_for conversation_message_broadcast_id
    return if (by_tags = count_jobs_by_tags).empty?

    by_tags[conversation_message_broadcast_id]
  end

  def self.count_jobs_by_tags
    jobs.map do |job|
      job.tags
    end.flatten.group_by { |id| id }.map do |id, size|
      [id, size.length]
    end.to_h
  end

  def self.delete_jobs_with_tag tag
    jobs.select do |job|
      job.tags.include? tag
    end.map(&:delete)
  end

  def self.user_ids_to_broadcast conversation_message_broadcast_id, sender_id
    ConversationMessageBroadcast.find(conversation_message_broadcast_id).user_ids - broadcasted_user_ids(conversation_message_broadcast_id, sender_id)
  end

  # find all users that have already been broadcasted
  # this case happens whenever a broadcast has timeout and we want to relaunch this broadcast
  def self.broadcasted_user_ids conversation_message_broadcast_id, sender_id
    JoinRequest
      .where.not(user_id: sender_id)
      .where(joinable_type: 'Entourage')
      .where(
        joinable_id: ChatMessage.where(message_type: :broadcast).where("metadata ->> 'conversation_message_broadcast_id' = '?'", conversation_message_broadcast_id).pluck(:messageable_id)
      ).pluck(:user_id).uniq.sort
  end
end
