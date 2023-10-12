class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :entourage, :entourage_moderation, :chat_message, :join_request, :neighborhoods_entourage

  def after_create record
    @record_changes = record.saved_changes
  end

  def after_update record
    @record_changes = record.saved_changes
  end

  def after_commit record
    return action(:create, record) if commit_is?(record, [:create])
    return action(:update, record) if commit_is?(record, [:update])
  end

  # @param verb :create, :update
  # @param record instance of entourage, chat_message, join_request
  def action(verb, record)
    PushNotificationTriggerJob.perform_later(record.class.name, verb, record.id, @record_changes)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
