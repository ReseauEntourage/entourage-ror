class PushNotificationTriggerJob
  include Sidekiq::Worker

  def perform class_name, verb, id, changes
    return unless record = class_name.constantize.find_by_id(id)

    PushNotificationTrigger.new(record, verb, JSON.parse(changes)).run
  end

  def self.perform_later class_name, verb, id, changes
    PushNotificationTriggerJob.perform_async(class_name, verb.to_s, id, changes.to_json)
  end
end
