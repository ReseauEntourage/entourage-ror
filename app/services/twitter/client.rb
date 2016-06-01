module Twitter
  class Client
    attr_reader :token

    def initialize(token:, token_secret:)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["ENTOURAGE_TWITTER_CONSUMER_KEY"]
        config.consumer_secret     = ENV["ENTOURAGE_TWITTER_CONSUMER_SECRET"]
        config.access_token        = token
        config.access_token_secret = token_secret
      end
    end

    #Twitter user attribute list : http://www.rubydoc.info/gems/twitter/Twitter/User
    def me
      client.verify_credentials.id
    end

    private
    attr_reader :client
  end

  class InvalidTokenError < StandardError; end
  class FacebookResponseWithError < StandardError; end
end