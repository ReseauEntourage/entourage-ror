module OrganizationAdmin
  module InvitationService
    def self.create_invitation invitee_email:, partner_id:, inviter_id:, invitee_attributes: {}
      inviter = User.find(inviter_id)
      unless inviter.admin?
        raise unless inviter.partner_id == partner_id
        raise unless OrganizationAdmin::Permissions.can_invite_member?(inviter)
      end

      invitation = PartnerInvitation.find_or_initialize_by(
        invitee_email: invitee_email,
        partner_id: partner_id,
        status: :pending,
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
      raise 'Invitation is not pending' unless invitation.pending?
      OrganizationAdminMailer.invitation(invitation.id).deliver_later
    end

    def self.delete_invitation invitation
      raise 'Invitation is not pending' unless invitation.pending?
      invitation.status = :deleted
      invitation.save
    end

    def self.mark_accepted_invitations_as_outdated user_id:, partner_id:
      previous_accepted_invitations =
        PartnerInvitation.where(
          partner_id: partner_id,
          invitee_id: user_id,
          status: :accepted
        )
      previous_accepted_invitations.each do |i|
        i.status = :outdated
        i.save
      end
    end

    def self.accept_invitation! invitation:, user:
      raise 'Invitation is not pending' unless invitation.pending?
      raise 'Already a member' if user.partner_id == invitation.partner_id

      user.assign_attributes(
        partner_id: invitation.partner_id,
        partner_admin: invitation.partner.users.empty?,
        partner_role_title: invitation.invitee_role_title,
      )

      invitation.assign_attributes(
        status: :accepted,
        invitee_id: user.id,
      )

      ApplicationRecord.transaction do
        mark_accepted_invitations_as_outdated(
          user_id: invitation.invitee_id,
          partner_id: invitation.partner_id
        )
        user.save!
        invitation.save!
      end
    end
  end
end
