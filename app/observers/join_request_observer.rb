class JoinRequestObserver < ActiveRecord::Observer
  observe :join_request

  def after_create(record)
    action(:create, record)
  end

  def after_update(record)
    return unless record.saved_change_to_status?

    action(:update, record)
  end

  private

  # @param verb :create, :update
  # @param record JoinRequest
  # sends a log to Slack
  def action(verb, record)
    return unless record.joinable
    return unless record.entourage?
    return unless record.pending?
    return if record.joinable.conversation?

    SlackServices::StackTrace.new(title: "Pending join_request detected on #{verb}, id: #{record.id}", stack_trace: "> #{caller.inspect}").notify
  rescue
    # we want this hook to never fail the main process
  end
end
