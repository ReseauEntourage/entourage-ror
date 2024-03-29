module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      join_request = build_join_request(status: JoinRequest::ACCEPTED_STATUS)

      if join_request.save
        invitation.update(status: EntourageInvitation::ACCEPTED_STATUS)

        group = invitation.invitable
        group.touch
      end
    end

    def reject!
      if build_join_request(status: JoinRequest::REJECTED_STATUS).save
        invitation.update(status: EntourageInvitation::REJECTED_STATUS)
      end
    end

    def quit!
      if build_join_request(status: JoinRequest::CANCELLED_STATUS).save
        invitation.update(status: EntourageInvitation::CANCELLED_STATUS)
      end
    end

    private
    attr_reader :invitation

    def invitable
      @invitable ||= invitation.invitable
    end

    def build_join_request status:
      join_request = JoinRequest.find_or_initialize_by(
        user: invitation.invitee,
        joinable: invitation.invitable
      )
      join_request.status = status

      joinable = invitation.invitable
      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'action'] then 'member'
        when ['entourage', 'outing'] then 'participant'
        when ['entourage', 'group']  then 'member'
        else raise 'Unhandled'
        end

      join_request
    end

    def invitee_name
      UserPresenter.new(user: invitation.invitee).display_name
    end

    def group
      @group ||= invitation.invitable
    end
  end
end
