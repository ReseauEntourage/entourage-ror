module EntourageServices
  class InvitationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def accept!
      if build_join_request(status: JoinRequest::ACCEPTED_STATUS).save
        invitation.update(status: EntourageInvitation::ACCEPTED_STATUS)
        invitation.invitable.touch
        send_notif(title: "Invitation acceptée",
                   content: "#{invitee_name} a accepté votre invitation",
                   accepted: true)
      end
    end

    def reject!
      if build_join_request(status: JoinRequest::REJECTED_STATUS).save
        invitation.update(status: EntourageInvitation::REJECTED_STATUS)
        send_notif(title: "Invitation refusée",
                   content: "#{invitee_name} a refusé votre invitation",
                   accepted: false)
      end
    end

    def quit!
      if build_join_request(status: JoinRequest::CANCELLED_STATUS).save
        invitation.update(status: EntourageInvitation::CANCELLED_STATUS)
        send_notif(title: "Invitation annulée",
                   content: "Vous avez annulé l'invitation de #{invitee_name}",
                   accepted: false)
      end
    end

    private
    attr_reader :invitation

    def build_join_request status:
      join_request = JoinRequest.new(user: invitation.invitee, joinable: invitation.invitable, status: status)

      joinable = invitation.invitable
      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'tour']   then 'member'
        when ['entourage', 'action'] then 'member'
        else raise 'Unhandled'
        end

      join_request
    end

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
