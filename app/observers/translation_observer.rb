class TranslationObserver < ActiveRecord::Observer
  observe :chat_message, :entourage, :neighborhood

  def after_commit record
    return if record.is_a?(Entourage) && record.conversation?

    return action(:create, record) if commit_is?(record, [:create])
    return action(:update, record) if commit_is?(record, [:update])
  end

  # @param verb :create, :update
  def action(verb, record)
    TranslationServices::Translator.new(record).translate!
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
