class AssistantAccountObserver < ActiveRecord::Observer
  # What the AI assistant did for an account goes with the account: its rows of assistant_actions
  # are deleted when the account is deleted or anonymized.
  #
  # `deleted` is the one switch of every path: the app (UserServices::DeleteUserService), the
  # back-office and the CNIL task (User#anonymize!), which all save `deleted: true` with
  # `save(validate: false)`. That is why this is an after_commit and not an after_validation.
  observe :user

  def after_commit user
    return unless user.saved_change_to_deleted? && user.deleted?

    purge(user)
  end

  private

  def purge user
    AssistantAction.where(user_id: user.id).delete_all
  rescue => e
    # never fail the deletion of an account because of the traces of the assistant
    Sentry.capture_exception(e)
  end
end
