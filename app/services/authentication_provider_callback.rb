class AuthenticationProviderCallback
  attr_accessor :on_login_success, :on_invalid_token, :on_save_user_error, :on_provider_error

  def login_success(&block)
    @on_login_success = block
  end

  def invalid_token(&block)
    @on_invalid_token = block
  end

  def provider_error(&block)
    @on_provider_error = block
  end

  def save_user_error(&block)
    @on_save_user_error = block
  end
end