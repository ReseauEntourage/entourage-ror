module JoinRequestsServices
  class AdminAcceptedJoinRequestBuilder
    def initialize(joinable:, user:)
      @joinable = joinable
      @user     = user
    end

    def create
      return false unless @user.admin?

      join_request = JoinRequest.new(joinable: @joinable, user: @user,  status: JoinRequest::ACCEPTED_STATUS)

      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'tour']   then 'member'
        when ['entourage', 'action'] then 'member'
        when ['entourage', 'outing'] then 'participant'
        else raise 'Unhandled'
        end
      
      join_request.joinable.number_of_people += 1

      if join_request.save

        title   = "Invitation acceptée"
        content = "Un membre de l'équipe Entourage a rejoint votre #{GroupService.name(joinable)} pour vous aider."
        meta    = { joinable_id: join_request.joinable_id,
                    joinable_type: join_request.joinable_type,
                    group_type: joinable.group_type,
                    type: "JOIN_REQUEST_ACCEPTED",
                    user_id: @user.id }

        PushNotificationService.new.send_notification(@user.first_name, title, content, [@joinable.user], meta)
      end

      join_request
    end

    private

    attr_reader :joinable
  end
end
