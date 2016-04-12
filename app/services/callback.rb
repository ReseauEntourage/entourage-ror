class Callback
  attr_accessor :on_success, :on_failure

  def success(&block)
    @on_success = block
  end

  def failure(&block)
    @on_failure = block
  end
end