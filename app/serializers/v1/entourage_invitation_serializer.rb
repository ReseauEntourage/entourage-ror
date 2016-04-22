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
      EntouragesUser.where(entourage: object.invitable, user: object.invitee).present?
    end
  end
end