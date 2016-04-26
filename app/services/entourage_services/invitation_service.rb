module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS)
    end

    def reject!
      JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS)
    end

    private
    attr_reader :invitation
  end
end