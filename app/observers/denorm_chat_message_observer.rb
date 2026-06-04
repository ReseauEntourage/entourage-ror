class DenormChatMessageObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return unless record.is_a?(ChatMessage)
    return unless record.messageable
    return unless commit_is?(record, [:create]) || record.saved_change_to_status?

    UnreadChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
    CountChatMessageJob.perform_later(record.messageable_type, record.messageable_id)

    broadcast_outing_chat_message(record) if new_outing_message?(record)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end

  def new_outing_message?(record)
    commit_is?(record, [:create]) &&
      record.message_type != 'status_update' &&
      record.messageable_type == 'Entourage' &&
      record.messageable.group_type == 'outing'
  end

  def broadcast_outing_chat_message(record)
    OutingChatChannel.broadcast_new_message(record)
  rescue => e
    Rails.logger.error "[OutingChatChannel] Broadcast failed: #{e.message}"
  end
end
