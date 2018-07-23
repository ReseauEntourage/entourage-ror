module ModerationServices
  module EntourageModeration
    module_function

    def moderator_for entourage
      return if entourage.community != 'entourage'
      User.find_by email: 'guillaume@entourage.social'
    end

    def on_create entourage
      moderator = moderator_for(entourage)
      return if moderator.nil?
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder
        .new(joinable: entourage, user: moderator)
        .create
    end
  end
end
