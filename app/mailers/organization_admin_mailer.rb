class OrganizationAdminMailer < ActionMailer::Base
  def invitation invitation_id
    @invitation = PartnerInvitation.find(invitation_id)

    headers(
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :org_admin_invitation,
        invitation_id: @invitation.id
      ),
      'X-Mailjet-Campaign' => :org_admin_invitation,
    )

    @inviter_name = UserPresenter.full_name(@invitation.inviter)
    @inviter_email = @invitation.inviter.email.squish.downcase
    mail(
      from: "associations@entourage.social",
      to: @invitation.invitee_email,
      subject: "#{@inviter_name} vous a invité(e) à rejoindre une organisation sur Entourage"
    )
  end
end
