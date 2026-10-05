class DenormChatMessageObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return unless record.is_a?(ChatMessage)
    return unless record.messageable
    return unless commit_is?(record, [:create]) || record.saved_change_to_status?

    UnreadChatMessageJob.perform_later(record.messageable_type, record.messageable_id)
    CountChatMessageJob.perform_later(record.messageable_type, record.messageable_id)

    impact_stats(record)
  end

  private

  # @see UserStat
  def impact_stats record
    return if UserStat::UNCOUNTED_MESSAGE_TYPES.include?(record.message_type.to_s)

    counter = if record.neighborhood?
      UserStat::NEIGHBORHOOD_MESSAGES
    elsif record.conversation?
      UserStat::CONVERSATION_MEMBERS
    end

    return unless counter

    UserImpactStatsJob.perform_async(record.user_id, counter)
  rescue => e
    # we never want to fail the message write because of a counter
    Rails.logger.warn "DenormChatMessageObserver#impact_stats #{e.message}"
  end

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
