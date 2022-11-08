class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :entourage, :chat_message, :join_request, :neighborhoods_entourage

  def after_create(record)
    action(:create, record)
  end

  def after_update(record)
    action(:update, record)
  end

  # @param verb :create, :update
  # @param record instance of entourage, chat_message, join_request
  def action(verb, record)
    PushNotificationTriggerJob.perform_later(record.class.name, verb, record.id, record.saved_changes)
  end
end
