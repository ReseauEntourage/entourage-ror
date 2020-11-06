module UserServices
  class UnreadMessages
    def initialize(user:)
      @user = user
    end

    def number_of_unread_messages
      count =
        FeedServices::MyFeedFinder.unread_count(user: user) +
        EntourageServices::InvitationService.unread_count(user: user)

      count = 99 if count > 99

      count
    end

    private
    attr_reader :user
  end
end
