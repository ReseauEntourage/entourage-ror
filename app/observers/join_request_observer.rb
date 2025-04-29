class JoinRequestObserver < ActiveRecord::Observer
  observe :join_request

  def after_create(record)
    action(:create, record)

    mailer(record)
    user_smalltalk(record)
  end

  def after_update(record)
    return unless record.saved_change_to_status?

    action(:update, record)
  end

  def after_destroy(record)
    action(:destroy, record)
  end

  private

  # @param verb :create, :update
  # @param record JoinRequest
  # sends a log to Slack
  def action(verb, record)
    return unless record.joinable
    return unless record.joinable.respond_to?(:members_has_changed!)

    record.joinable.members_has_changed!
  rescue
    # we want this hook to never fail the main process
  end

  def mailer(record)
    return unless record.user
    return unless record.joinable.respond_to?(:outing?) && record.joinable.outing?
    return if record.user_id == record.joinable.user_id

    GroupMailer.event_joined_confirmation(record.joinable_id, record.user_id).deliver_later
  end

  def user_smalltalk(record)
    return unless record.user
    return unless record.smalltalk?

    UserSmalltalk
      .where(user: record.user, smalltalk: record.joinable)
      .update_all(member_status: record.status)
  end
end
