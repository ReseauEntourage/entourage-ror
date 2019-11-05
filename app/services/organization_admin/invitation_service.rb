module OrganizationAdmin
  module InvitationService
    def self.create_invitation invitee_email:, partner_id:, inviter_id:, invitee_attributes: {}
      inviter = User.find(inviter_id)
      raise unless inviter.partner_id == partner_id || inviter.admin?

      invitation = PartnerInvitation.find_or_initialize_by(
        invitee_email: invitee_email,
        partner_id: partner_id,
      )

      invitation.assign_attributes(
        inviter_id: inviter_id,
        invited_at: Time.zone.now,
      )

      invitee_attributes = invitee_attributes.symbolize_keys
      invitation.assign_attributes(
        invitee_name:       invitee_attributes[:invitee_name],
        invitee_role_title: invitee_attributes[:invitee_role_title],
      )

      invitation.generate_new_token

      invitation.save

      return invitation
    end

    def self.deliver invitation
      raise "Invitation is not pending" unless invitation.pending?
      OrganizationAdminMailer.invitation(invitation.id).deliver_later
    end
  end
end
