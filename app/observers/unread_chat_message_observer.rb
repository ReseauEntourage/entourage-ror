class UnreadChatMessageObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return unless record.is_a?(ChatMessage)
    return unless ['Entourage', 'Neighborhood'].include?(record.messageable_type)

    if record.messageable_type == 'Entourage'
      return unless record.messageable.outing?
    end

    return unless commit_is?(record, [:create])

    UnreadChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
