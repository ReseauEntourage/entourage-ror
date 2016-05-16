module Twitter
  class TwitterAuthenticator
    def initialize(token:)
      @client = Twitter::Client.new(token: token)
      @callback = AuthenticationProviderCallback.new
    end

    def authenticate
      yield callback if block_given?

      begin
        update_user
      rescue Twitter::InvalidTokenError => e
        log_exception(e)
        callback.on_invalid_token.try(:call, client.token)
      rescue Twitter::TwitterResponseWithError => e
        log_exception(e)
        callback.on_provider_error.try(:call, e.message)
      end
    end

    private
    attr_reader :client, :callback

    def update_user
      twitter = TwitterAuthenticationProvider.select(:user_id).where(provider_id: facebook_user.try(:[], "id")).first
      if twitter
        Rails.logger.info "Update user from twitter : #{twitter_user.inspect}"
        user = update_user_from_twitter(user: twitter.user)
      end
      user
    end

    def update_user_from_twitter(user:)
      user = Twitter::TwitterUserBuilder.new(twitter_user: twitter_user).update_user(user)
      if user.save
        callback.on_login_success.try(:call, user)
      else
        callback.on_save_user_error.try(:call, user)
      end
      user
    end

    def twitter_user
      @twitter_user ||= client.me
    end

    def log_exception(e)
      Rails.logger.error e
      Raven.capture_exception(e) if Rails.env.production?
    end
  end

  class InvalidTokenError < StandardError; end
  class TwitterResponseWithError < StandardError; end
end