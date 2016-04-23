module V1
  class EntourageInvitationSerializer < ActiveModel::Serializer
    attributes :id,
               :inviter_id,
               :invitation_mode,
               :phone_number,
               :entourage_id,
               :accepted

    def entourage_id
      object.invitable_id
    end

    def accepted
      JoinRequest.where(joinable: object.invitable, user: object.invitee, status: JoinRequest::ACCEPTED_STATUS).present?
    end
  end
end