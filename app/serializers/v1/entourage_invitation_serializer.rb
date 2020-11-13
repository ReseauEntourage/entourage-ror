module V1
  class EntourageInvitationSerializer < ActiveModel::Serializer
    attributes :id,
               :invitation_mode,
               :phone_number,
               :status,
               :entourage_id,
               :title,
               :inviter

    def inviter
      inviter_name =
        if object.invitation_mode == 'partner_following'
          object.inviter.partner.name
        else
          UserPresenter.new(user: object.inviter).display_name
        end
      {
        display_name: inviter_name
      }
    end

    def entourage_id
      object.invitable_id
    end

    def title
      object.invitable.title
    end

    def status
      join_request = JoinRequest.where(joinable: object.invitable, user: object.invitee).first
      join_request.present? ? join_request.status : object.status
    end
  end
end
