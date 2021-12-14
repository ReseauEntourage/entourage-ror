class JoinRequestObserver < ActiveRecord::Observer
  observe :join_request

  def after_create(record)
    return unless record.pending?

    action(:create, record)
  end

  def after_update(record)
    return unless record.pending?
    return unless record.saved_change_to_status?

    action(:update, record)
  end

  private

  # @param verb :create, :update
  # @param record JoinRequest
  # sends a log to Slack
  def action(verb, record)
    SlackServices::StackTrace.new(title: "Pending join_request detected on #{verb}, id: #{record.id}", stack_trace: "> #{caller.inspect}").notify
  end
end
