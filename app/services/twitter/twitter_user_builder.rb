module Twitter
  class TwitterUserBuilder
    def initialize(twitter_user:)
      @twitter_user = twitter_user
    end

    def update_user(user)
      user.tap do |user|
        #We can only get a name and a location from twitter
      end
    end

    private
    attr_reader :twitter_user
  end
end
