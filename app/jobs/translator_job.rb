class TranslatorJob
  include Sidekiq::Worker

  sidekiq_options :retry => true, queue: :translation

  def perform _, class_name, id
    return unless record = class_name.constantize.unscoped.find_by(id: id)

    record.translate!
  end

  def self.perform_later class_name, id
    # keyword "translation" is set to identify this job in workers
    # see PushNotificationTriggerJob.translation_job_in_progress?
    TranslatorJob.perform_async("translation", class_name, id)
  end
end
