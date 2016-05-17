module Twitter
  class TwitterUserBuilder
    def initialize(twitter_user:)
      @twitter_user = twitter_user
    end

    def update_user(user)
      user.tap do |user|
        user.email ||= twitter_user["email"] unless twitter_user["email"].nil?
        user.first_name ||= twitter_user["first_name"]
        user.last_name ||= twitter_user["last_name"]
      end
    end

    private
    attr_reader :twitter_user
  end
end