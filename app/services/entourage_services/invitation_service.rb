module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      if JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS)
        invitation.update(status: EntourageInvitation::ACCEPTED_STATUS)
      end
    end

    def reject!
      if JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS)
        invitation.update(status: EntourageInvitation::REJECTED_STATUS)
      end
    end

    private
    attr_reader :invitation
  end
end