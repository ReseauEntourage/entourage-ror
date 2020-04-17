module UserServices
  class UnreadMessages
    def initialize(user:)
      @user = user
    end

    def number_of_unread_messages
      FeedServices::MyFeedFinder.unread_count(user: user)
    end

    private
    attr_reader :user
  end
end
