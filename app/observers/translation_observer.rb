class TranslationObserver < ActiveRecord::Observer
  observe :chat_message

  def after_commit record
    return action(:create, record) if commit_is?(record, [:create])
  end

  # @param verb :create
  def action(verb, record)
    TranslationServices::Translator.new(record).translate!
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
