class Callback
  attr_accessor :on_create_success, :on_create_failure

  def create_success(&block)
    @on_create_success = block
  end

  def create_failure(&block)
    @on_create_failure = block
  end
end