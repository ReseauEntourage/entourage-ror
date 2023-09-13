class TranslationObserver < ActiveRecord::Observer
  observe :chat_message, :entourage, :neighborhood

  def after_commit record
    return if record.is_a?(Entourage) && record.conversation?
    return unless record.persisted?

    return action(:create, record) if commit_is?(record, [:create])
    return action(:update, record) if commit_is?(record, [:update])
  end

  # @param verb :create, :update
  def action(verb, record)
    TranslatorJob.perform_later(record.class.name, record.id)
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end
