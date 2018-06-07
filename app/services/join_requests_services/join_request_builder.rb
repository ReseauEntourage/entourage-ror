module JoinRequestsServices
  class JoinRequestBuilder
    def initialize(joinable:, user:, message:, distance:)
      @joinable = joinable
      @user = user
      @message = message
      @distance = distance
      @callback = Callback.new
    end

    def create
      yield callback if block_given?

      join_request = JoinRequest.new(joinable: joinable, user: user, message: message, distance: distance)

      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'tour']   then 'member'
        when ['entourage', 'action'] then 'member'
        else raise 'Unhandled'
        end

      if join_request.save
        is_onboarding = joinable.is_a?(Entourage) && Onboarding::V1.is_onboarding?(joinable)

        unless is_onboarding
          NewJoinRequestNotifyJob.set(wait: 1.minute).perform_later(joinable.class.name,
                                             joinable.id,
                                             user.id,
                                             "NEW_JOIN_REQUEST",
                                             message)
        end

        if joinable.is_a?(Entourage)
          EntourageServices::UsersAppetenceBuilder.new(user: user).join_entourage(entourage: joinable)
        end

        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    private
    attr_reader :joinable, :callback, :user, :message, :distance
  end
end