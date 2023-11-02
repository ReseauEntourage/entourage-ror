class PushNotificationTriggerJob
  RETRY_MAX = 3
  RETRY_DURATION = 10.seconds

  include Sidekiq::Worker

  def perform class_name, verb, id, changes, retry_count = 0
    return retry_push_notification_later(class_name, verb, id, changes, retry_count) if retry_count < 1

    if retry_count <= RETRY_MAX
      return retry_push_notification_later(class_name, verb, id, changes, retry_count) if translation_job_in_queue?(class_name, id)
      return retry_push_notification_later(class_name, verb, id, changes, retry_count) if translation_job_in_progress?(class_name, id)
    end

    PushNotificationTrigger.new(class_name.constantize.find(id), verb, JSON.parse(changes)).run
  end

  def self.perform_later class_name, verb, id, changes
    PushNotificationTriggerJob.perform_async(class_name, verb.to_s, id, changes.to_json)
  end

  private

  def translation_job_in_queue? class_name, id
    Sidekiq::Queue.new("translation").any? do |job|
      job.args == ["translation", class_name, id]
    end
  end

  def translation_job_in_progress? class_name, id
    Sidekiq::Workers.new.detect do |_, _, work|
      work["payload"]["args"] == ["translation", class_name, id]
    end.present?
  end

  def retry_push_notification_later class_name, verb, id, changes, retry_count
    PushNotificationTriggerJob.perform_in(RETRY_DURATION, class_name, verb, id, changes, retry_count + 1)
  end
end
