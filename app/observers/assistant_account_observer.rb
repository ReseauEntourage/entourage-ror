class AssistantAccountObserver < ActiveRecord::Observer
  # When an account is deleted or anonymized:
  # - what the AI assistant did for it goes with it: its rows of assistant_actions are deleted;
  # - the assistant is told, so that it erases its own memory of the account (a job is queued, see
  #   AssistantAccountEventJob).
  #
  # Neither ever fails the deletion of the account.
  #
  # `deleted` is the one switch of every path: the app (UserServices::DeleteUserService), the
  # back-office and the CNIL task (User#anonymize!), which all save `deleted: true` with
  # `save(validate: false)`. That is why this is an after_commit and not an after_validation.
  observe :user

  def after_commit user
    # An account that was already deleted can be anonymized afterwards: `deleted` does not change then,
    # but the status becomes `anonymized`.
    deleted_now = user.saved_change_to_deleted? && user.deleted?
    anonymized_now = user.deleted? && user.saved_change_to_validation_status? && user.anonymized?
    return unless deleted_now || anonymized_now

    purge(user)
    notify_assistant(user)
  end

  private

  def notify_assistant user
    return unless Assistant::AccountEvents.enabled?

    AssistantAccountEventJob.perform_async(user.uuid, Assistant::AccountEvents.event_for(user), Time.current.iso8601)
  rescue => e
    # never fail the deletion of an account because the assistant could not be told
    Sentry.capture_exception(e)
  end

  def purge user
    AssistantAction.where(user_id: user.id).delete_all
  rescue => e
    # never fail the deletion of an account because of the traces of the assistant
    Sentry.capture_exception(e)
  end
end
