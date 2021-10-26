class UserBlockObserver < ActiveRecord::Observer
  observe :user

  AUTO_CLOSE_MESSAGE = "Cette action a été clôturée car son auteur a quitté le réseau Entourage. N'hésitez pas à rejoindre d'autres actions solidaires sur l'app !"

  def after_update user
    return unless user.saved_change_to_validation_status? || user.saved_change_to_deleted?

    historizes user

    if user.saved_change_to_validation_status? && (user.blocked? || user.anonymized?) || user.saved_change_to_deleted? && user.deleted?
      close_entourages! user
      block_notifications! user
    end
  end

  def historizes user
    return historizes_deleted(user) if user.saved_change_to_deleted? && user.deleted?

    method_name = "historizes_#{user.validation_status}"

    return historizes_default unless respond_to?(method_name, true)

    send(method_name, user)
  end

  def close_entourages! user
    entourage_ids = Entourage.where(user_id: user.id, status: :open).pluck(:id)

    EntouragesCloserJob.perform_later(entourage_ids)
  end

  def create_chat_message_for_entourages! user
    entourage_ids = Entourage.where(user_id: user.id, group_type: [:action, :outing], status: :open).pluck(:id)

    ChatMessagesEntourageJob.perform_later(user.id, entourage_ids, AUTO_CLOSE_MESSAGE)
  end

  # @notice do not delete this method; we use it as documentation
  def block_notifications! user
    # @see PushNotificationService.send_notification
  end

  protected

  def historizes_default user
    UserHistory.create({
      user_id: user.id,
      updater_id: nil,
      kind: 'unknown-status',
      metadata: {}
    })
  end

  def historizes_validated user
    # done in user.unblock!
  end

  def historizes_anonymized user
    # done in user.anonymize!
  end

  def historizes_blocked user
    if user.unblock_at.present?
      return historizes_temporary_blocked user
    end

    historizes_permanent_blocked user
  end

  def historizes_temporary_blocked user
    # done in user.block!
  end

  def historizes_permanent_blocked user
    # done in user.temporary_block!
  end

  def historizes_deleted user
    UserHistory.create({
      user_id: user.id,
      updater_id: user.id,
      kind: 'deleted',
      metadata: {
        email_was: user.anonymized? ? 'anonymized' : user.email_was
      }
    })
  end
end
