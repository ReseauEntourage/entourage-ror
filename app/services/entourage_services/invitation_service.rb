module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS)
    end

    def reject!

    end

    private
    attr_reader :invitation
  end
end