class TranslatorJob
  include Sidekiq::Worker

  sidekiq_options :retry => true, queue: :translation

  def perform class_name, id
    TranslationServices::Translator.new(class_name.constantize.unscoped.find(id)).translate!
  end

  def self.perform_later class_name, id
    TranslatorJob.perform_async(class_name, id)
  end
end
