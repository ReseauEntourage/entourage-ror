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
      UserSerializer.new(object.inviter, root: false)
    end

    def entourage_id
      object.invitable_id
    end

    def title
      object.invitable.title
    end

    def status
      join_request = JoinRequest.where(joinable: object.invitable, user: object.invitee).first
      join_request.present? ? join_request.status : "pending"
    end
  end
end
