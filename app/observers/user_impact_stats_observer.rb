class UserImpactStatsObserver < ActiveRecord::Observer
  # Write-side triggers of every impact count (@see UserStat):
  #
  #   action created, destroyed or status changed      -> its creator: action_creations
  #   neighborhood message created, destroyed or
  #   status changed                                    -> its author: neighborhood_messages
  #   conversation message created, destroyed or
  #   status changed                                    -> its author: conversation_members
  #   conversation member added or removed              -> the other authors of the
  #                                                        conversation: conversation_members
  #
  # past_outing_participations_count has no trigger: it changes as time passes,
  # so V1::Users::SummarySerializer computes it at read time.
  observe :entourage, :chat_message, :join_request

  def after_commit record
    case record
    when Entourage then action_changed(record)
    when ChatMessage then message_changed(record)
    when JoinRequest then membership_changed(record)
    end
  rescue => e
    # we never want to fail a write because of a counter
    Rails.logger.warn "UserImpactStatsObserver #{e.message}"
  end

  private

  def action_changed entourage
    return unless entourage.action?
    return unless commit_is?(entourage, [:create, :destroy]) || entourage.saved_change_to_status?

    enqueue(entourage.user_id, UserStat::ACTION_CREATIONS)
  end

  def message_changed message
    return unless message.messageable
    return unless commit_is?(message, [:create, :destroy]) || message.saved_change_to_status?
    return if UserStat::UNCOUNTED_MESSAGE_TYPES.include?(message.message_type.to_s)

    if message.neighborhood?
      enqueue(message.user_id, UserStat::NEIGHBORHOOD_MESSAGES)
    elsif message.conversation?
      enqueue(message.user_id, UserStat::CONVERSATION_MEMBERS)
    end
  end

  # members are counted whatever their membership status, so only an added or
  # removed membership changes the count of those who wrote in the conversation
  def membership_changed join_request
    return unless commit_is?(join_request, [:create, :destroy])
    return unless join_request.joinable # the conversation itself was destroyed
    return unless join_request.conversation?

    UserStat.conversation_author_ids(join_request.joinable_id, except: join_request.user_id).each do |user_id|
      enqueue(user_id, UserStat::CONVERSATION_MEMBERS)
    end
  end

  def enqueue user_id, counter
    UserImpactStatsJob.perform_async(user_id, counter)
  end

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
