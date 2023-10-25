class TranslatorJob
  include Sidekiq::Worker

  sidekiq_options :retry => true, queue: :translation

  def perform class_name, id
    return unless record = class_name.constantize.unscoped.find_by(id: id)

    record.translate!
  end

  def self.perform_later class_name, id
    TranslatorJob.perform_async(class_name, id)
  end
end
