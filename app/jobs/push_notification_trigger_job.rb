class PushNotificationTriggerJob
  include Sidekiq::Worker

  def perform class_name, verb, id, changes
    PushNotificationTrigger.new(class_name.constantize.find(id), verb, JSON.parse(changes)).run
  end

  def self.perform_later class_name, verb, id, changes
    PushNotificationTriggerJob.perform_async(class_name, verb.to_s, id, changes.to_json)
  end
end
