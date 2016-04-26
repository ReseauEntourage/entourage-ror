module V1
  class EntourageInvitationSerializer < ActiveModel::Serializer
    attributes :id,
               :inviter_id,
               :invitation_mode,
               :phone_number,
               :entourage_id,
               :status

    def entourage_id
      object.invitable_id
    end

    def status
      join_request = JoinRequest.where(joinable: object.invitable, user: object.invitee).first
      join_request.present? ? join_request.status : "pending"
    end
  end
end