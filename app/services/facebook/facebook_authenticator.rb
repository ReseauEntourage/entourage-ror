module Facebook
  class FacebookAuthenticator
    def initialize(token:)
      @client = Facebook::Client.new(token: token)
      @callback = FacebookCallback.new
    end

    def authenticate
      yield callback if block_given?

      begin
        update_user
      rescue Facebook::InvalidTokenError => e
        log_exception(e)
        callback.on_invalid_facebook_token.try(:call, client.token)
      rescue Facebook::FacebookResponseWithError => e
        log_exception(e)
        callback.on_facebook_error.try(:call, e.message)
      end
    end

    private
    attr_reader :client, :callback

    def update_user
      facebook = FacebookAuthenticationProvider.select(:user_id).where(provider_id: facebook_user.try(:[], "id")).first
      if facebook
        Rails.logger.info "Update user from facebook : #{facebook_user.inspect}"
        user = update_user_from_facebook(user: facebook.user)
      end
      user
    end

    def update_user_from_facebook(user:)
      user = Facebook::FacebookUserBuilder.new(facebook_user: facebook_user).update_user(user)
      if user.save
        callback.on_login_success.try(:call, user)
      else
        callback.on_save_user_error.try(:call, user)
      end
      user
    end

    def facebook_user
      @facebook_user ||= client.me
    end

    def log_exception(e)
      Rails.logger.error e
      Raven.capture_exception(e) if Rails.env.production?
    end
  end

  class FacebookCallback
    attr_accessor :on_login_success, :on_invalid_facebook_token, :on_save_user_error, :on_facebook_error

    def login_success(&block)
      @on_login_success = block
    end

    def invalid_facebook_token(&block)
      @on_invalid_facebook_token = block
    end

    def facebook_error(&block)
      @on_facebook_error = block
    end

    def save_user_error(&block)
      @on_save_user_error = block
    end
  end
end
