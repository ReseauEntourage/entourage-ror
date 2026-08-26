class ConversationBroadcastObserver < ActiveRecord::Observer
  observe :chat_message, :user_reaction, :join_request

  def after_commit(record)
    case record
    when ChatMessage  then handle_chat_message(record)
    when UserReaction then handle_user_reaction(record)
    when JoinRequest  then handle_join_request(record)
    end
  end

  private

  def handle_chat_message(record)
    return unless record.messageable
    return if record.message_type == 'status_update'

    if commit_is?(record, [:create])
      ConversationChannel.broadcast_chat_message_created(record)
    elsif commit_is?(record, [:update]) && record.saved_change_to_status?
      ConversationChannel.broadcast_chat_message_updated(record)
    end
  rescue => e
    Rails.logger.error "[ConversationBroadcastObserver] ChatMessage broadcast failed: #{e.message}"
  end

  def handle_user_reaction(record)
    return unless record.instance_type == 'ChatMessage'

    chat_message = ChatMessage.find_by(id: record.instance_id)
    return unless chat_message&.messageable

    if commit_is?(record, [:create])
      ConversationChannel.broadcast_user_reaction_added(record, chat_message)
    elsif commit_is?(record, [:destroy])
      ConversationChannel.broadcast_user_reaction_removed(record, chat_message)
    end
  rescue => e
    Rails.logger.error "[ConversationBroadcastObserver] UserReaction broadcast failed: #{e.message}"
  end

  def handle_join_request(record)
    return unless record.joinable
    return unless commit_is?(record, [:create, :update])
    return unless record.saved_change_to_status?

    if record.status == JoinRequest::ACCEPTED_STATUS
      ConversationChannel.broadcast_member_joined(record)
    elsif record.status_before_last_save == JoinRequest::ACCEPTED_STATUS
      ConversationChannel.broadcast_member_left(record)
    end
  rescue => e
    Rails.logger.error "[ConversationBroadcastObserver] JoinRequest broadcast failed: #{e.message}"
  end

  def commit_is?(record, actions)
    record.send(:transaction_include_any_action?, actions)
  end
end
