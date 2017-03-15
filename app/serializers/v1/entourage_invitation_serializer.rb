module V1
  class EntourageInvitationSerializer < ActiveModel::Serializer
    attributes :id,
               :invitation_mode,
               :phone_number,
               :status,
               :entourage_id,
               :inviter

    def inviter
      UserSerializer.new(object.inviter, root: false)
    end

    def entourage_id
      object.invitable_id
    end

    def status
      join_request = JoinRequest.where(joinable: object.invitable, user: object.invitee).where('status NOT LIKE ?', JoinRequest::CANCELLED_STATUS).first
      join_request.present? ? join_request.status : "pending"
    end
  end
end