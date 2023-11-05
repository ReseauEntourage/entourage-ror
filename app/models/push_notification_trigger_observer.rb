class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :translation, :entourage, :entourage_moderation, :join_request, :neighborhoods_entourage

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

  def action(verb, record)
    return if skip?(verb, record)

    record = record.instance if verb == :create && record.is_a?(Translation)

    PushNotificationTriggerJob.perform_later(record.class.name, verb, record.id, @record_changes)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end

  def skip? verb, record
    return true if verb == :update && record.is_a?(Translation)

    # chat_messages and entourages on creation are triggered when translations are triggered
    return true if verb == :create && record.is_a?(ChatMessage)
    return true if verb == :create && record.is_a?(Entourage)

    false
  end
end
