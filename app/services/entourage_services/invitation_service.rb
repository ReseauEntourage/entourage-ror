module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      if JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS)
        invitation.update(status: EntourageInvitation::ACCEPTED_STATUS)
        send_notif(title: "Invitation accepté",
                   content: "#{invitee_name} a accepté votre invitation",
                   accepted: true)
      end
    end

    def reject!
      if JoinRequest.create(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS)
        invitation.update(status: EntourageInvitation::REJECTED_STATUS)
        send_notif(title: "Invitation refusé",
                   content: "#{invitee_name} a refusé votre invitation",
                   accepted: false)
      end
    end

    private
    attr_reader :invitation

    def send_notif(title:, content:, accepted:)
      meta = {
          type: "INVITATION_STATUS",
          inviter_id: invitation.inviter.id,
          invitee_id: invitation.invitee.id,
          feed_id: invitation.invitable_id,
          feed_type: invitation.invitable_type,
          accepted: accepted
      }
      PushNotificationService.new.send_notification(invitee_name, title, content, [invitation.inviter], meta)
    end

    def invitee_name
      UserPresenter.new(user: invitation.invitee).display_name
    end
  end
end