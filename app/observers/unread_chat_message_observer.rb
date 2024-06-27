class UnreadChatMessageObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return unless record.is_a?(ChatMessage)
    return unless record.messageable && record.messageable.is_a?(Neighborhood)
    return unless commit_is?(record, [:create])

    UnreadChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
