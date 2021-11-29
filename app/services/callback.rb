class Callback
  attr_accessor :on_success, :on_failure, :on_unauthorized

  def success(&block)
    @on_success = block
  end

  def failure(&block)
    @on_failure = block
  end

  def unauthorized(&block)
    @on_unauthorized = block
  end

  def action_or_failure(block, user)
    block.present? ? block.call(user) : @on_failure.call(user)
  end
end
