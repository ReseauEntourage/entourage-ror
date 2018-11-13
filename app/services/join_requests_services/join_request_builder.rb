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
        when ['entourage', 'outing'] then 'participant'
        when ['pfp',       'outing'] then 'participant'
        when ['pfp', 'neighborhood'] then 'member'
        when ['pfp', 'private_circle'] then 'visitor'
        else raise 'Unhandled'
        end

      join_request.status = JoinRequest::ACCEPTED_STATUS if joinable.public

      if join_request.save
        is_onboarding = joinable.is_a?(Entourage) && Onboarding::V1.is_onboarding?(joinable)

        if join_request.is_accepted?
          joinable.class.increment_counter(:number_of_people, joinable.id)

          self.class.notify_auto_join_to_creator(join_request)
          CommunityLogic.for(joinable).group_joined(join_request)
        elsif is_onboarding
          # nothing!
        else
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

    def self.notify_auto_join_to_creator join_request
      user = join_request.user
      joinable = join_request.joinable

      display_name = user.first_name.strip
      display_name += " " + user.last_name.strip.first + "." if user.last_name.present?
      join_message = "#{display_name} vient de rejoindre votre #{GroupService.name joinable}"
      join_message += ' "' + joinable.title + '"' if joinable.is_a?(Entourage)

      PushNotificationService.new.send_notification(
        display_name,
        "Nouveau membre",
        join_message,
        [joinable.user],
        {
          joinable_id: joinable.id,
          joinable_type: join_request.joinable_type,
          group_type: joinable.group_type,
          type: "JOIN_REQUEST_ACCEPTED",
          user_id: user.id
        }
      )
    end

    private
    attr_reader :joinable, :callback, :user, :message, :distance
  end
end