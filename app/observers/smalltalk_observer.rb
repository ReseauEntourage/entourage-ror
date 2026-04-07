class SmalltalkObserver < ActiveRecord::Observer
  observe :smalltalk

  def after_commit smalltalk
    return unless verb(smalltalk).present?

    SmalltalkServices::Messager.new(smalltalk, verb(smalltalk)).run
  end

  private

  def commit_is? smalltalk, actions
    smalltalk.send(:transaction_include_any_action?, actions)
  end

  def verb smalltalk
    return :create if commit_is?(smalltalk, [:create])
    return :update if commit_is?(smalltalk, [:update])

    nil
  end
end
