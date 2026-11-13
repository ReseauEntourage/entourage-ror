class NextStepAccountObserver < ActiveRecord::Observer
  # An account that becomes deleted loses the engine's history: next steps keep
  # the segment and the profile of the person, a precarity included (design.md,
  # decision 14).
  #
  # `deleted` is the one switch of every path: the app (UserServices::DeleteUserService),
  # the back-office and the CNIL task (User#anonymize!), which all save `deleted: true`.
  observe :user

  def after_commit user
    return unless user.saved_change_to_deleted? && user.deleted?

    NextSteps::Purge.for_user(user.id)
  rescue => e
    # never fail the deletion of an account because of the engine's history
    Sentry.capture_exception(e)
  end
end
