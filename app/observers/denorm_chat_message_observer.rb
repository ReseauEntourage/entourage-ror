class DenormChatMessageObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return unless record.is_a?(ChatMessage)
    return unless record.messageable
    return unless commit_is?(record, [:create]) || record.saved_change_to_status?

    UnreadChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
    CountChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
