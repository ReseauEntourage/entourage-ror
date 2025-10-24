module OrganizationAdmin
  class InvitationsController < BaseController
    before_action :ensure_can_invite_member!, except: [:join, :accept]

    skip_before_action :authenticate_user!, only: [:join]
    skip_before_action :ensure_org_member!, only: [:join, :accept]

    layout_options active_menu: :invitations

    def index
      partner_id = current_user.partner_id
      invitations = PartnerInvitation.where(partner_id: partner_id)

      @status = params[:status] == 'accepted' ? :accepted : :pending

      accepted_invitations = invitations
        .where(status: :accepted)
        .joins(:invitee).where(users: {partner_id: partner_id})
        .order(accepted_at: :desc)

      pending_invitations = invitations
          .where(status: :pending)
          .order(invited_at: :desc)

      @invitations = @status == :accepted ? accepted_invitations : pending_invitations
      @counts = {
        accepted: accepted_invitations.count,
        pending:  pending_invitations.count
      }
    end

    def new
      @invitation = PartnerInvitation.new
    end

    def create
      @invitation = OrganizationAdmin::InvitationService.create_invitation(
        invitee_email: invitation_params[:invitee_email],
        partner_id: current_user.partner_id,
        inviter_id: current_user.id,
        invitee_attributes: invitation_params.except(:invitee_email).to_h
      )

      return render :new if @invitation.errors.any?

      OrganizationAdmin::InvitationService.deliver(@invitation)

      flash[:success] = 'Invitation envoyée !'
      redirect_to organization_admin_invitations_path
    end

    # DELETE organization_admin_invitation_path
    def destroy
      invitation = PartnerInvitation.where(partner_id: current_user.partner_id).find(params[:id])

      if OrganizationAdmin::InvitationService.delete_invitation(invitation)
        flash[:success] = 'Invitation révoquée !'
      else
        flash[:error] = invitation.errors.full_messages.to_sentence
      end
      redirect_to organization_admin_invitations_path
    end

    # resend_organization_admin_invitation_path
    def resend
      invitation = PartnerInvitation.where(partner_id: current_user.partner_id).find(params[:id])
      raise 'Invitation is not pending' unless invitation.pending?
      OrganizationAdmin::InvitationService.deliver(invitation)

      flash[:success] = 'Invitation envoyée à nouveau !'
      redirect_to organization_admin_invitations_path
    end

    def join
      @invitation = PartnerInvitation.find_by(token: params[:token])
      @invitation = nil unless @invitation.pending?
      if @invitation && current_user && current_user.partner_id == @invitation.partner_id
        return redirect_to organization_admin_path
      end
    end

    def accept
      invitation = PartnerInvitation.find_by(token: params[:token])

      if current_user.partner_id == invitation.partner_id
        return redirect_to organization_admin_path
      end

      raise 'Invitation is not pending' unless invitation.pending?

      current_user.assign_attributes(
        first_name: params[:first_name],
        last_name:  params[:last_name],
        email:      params[:email],
      )
      unless current_user.has_password?
        current_user.password = params[:password]
      end

      begin
        current_user.save
        OrganizationAdmin::InvitationService.accept_invitation!(
          invitation: invitation, user: current_user)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error(e)

        return redirect_to join_organization_admin_invitation_path(token: invitation.token, error: :unknown)
      end

      redirect_to organization_admin_path
    end

    protected

    def ensure_can_invite_member!
      unless OrganizationAdmin::Permissions.can_invite_member?(current_user)
        render text: "Vous n'avez pas la permission d'inviter un membre", status: :unauthorized
      end
    end

    def invitation_params
      params.require(:partner_invitation).permit(
        :invitee_email, :invitee_name, :invitee_role_title
      )
    end
  end
end
