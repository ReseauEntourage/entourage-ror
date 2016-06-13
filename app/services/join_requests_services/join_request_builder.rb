module JoinRequestsServices
  class JoinRequestBuilder
    def initialize(joinable:, user:, message:)
      @joinable = joinable
      @user = user
      @message = message
      @callback = Callback.new
    end

    def create
      yield callback if block_given?

      join_request = JoinRequest.new(joinable: joinable, user: user, message: message)
      if join_request.save
        notify_members(join_request.joinable_type)
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    private
    attr_reader :joinable, :callback, :user, :message

    def notify_members(type)
      recipients = joinable.members.includes(:join_requests).where(join_requests: {status: "accepted"})
      PushNotificationService.new.send_notification(UserPresenter.new(user: user).display_name,
                                                    "Demande en attente",
                                                    "Un nouveau membre souhaite rejoindre votre maraude",
                                                    recipients,
                                                    {joinable_id: joinable.id,
                                                     joinable_type: type,
                                                     type: "NEW_JOIN_REQUEST",
                                                     user_id: user.id})
    end
  end
end