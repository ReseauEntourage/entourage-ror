class JoinRequestObserver < ActiveRecord::Observer
  observe :join_request

  def after_create(record)
    action(:create, record)
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
end
