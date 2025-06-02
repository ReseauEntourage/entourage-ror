class SmalltalkObserver < ActiveRecord::Observer
  observe :smalltalk, :join_request

  def after_commit record
    return unless verb(record).present?

    SmalltalkServices::Messager.new(record, verb(record)).run
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end

  def verb record
    return :create if commit_is?(record, [:create])
    return :update if commit_is?(record, [:update])

    nil
  end
end
