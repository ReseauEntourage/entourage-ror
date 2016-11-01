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
        NewJoinRequestNotifyJob.set(wait: 1.minute).perform_later(joinable.class.name,
                                           joinable.id,
                                           user.id,
                                           "NEW_JOIN_REQUEST",
                                           message)
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    private
    attr_reader :joinable, :callback, :user, :message
  end
end