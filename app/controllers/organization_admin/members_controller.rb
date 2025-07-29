module OrganizationAdmin
  class MembersController < BaseController
    before_action :ensure_can_edit_member!, except: [:index, :show]
    before_action :ensure_can_remove_member!, only: [:destroy]

    layout_options active_menu: :members

    def index
      partner = current_user.partner
      @members = partner.users.order(:last_name, :first_name)
    end

    def show
      partner = current_user.partner
      member = partner.users.find(params[:id])
      redirect_to edit_organization_admin_member_path(member)
    end

    def edit
      partner = current_user.partner
      @member = partner.users.find(params[:id])
    end

    def update
      partner = current_user.partner
      member = partner.users.find(params[:id])
      if member.update(member_params)
        flash[:success] = 'Modifications enregistrées !'
      else
        flash[:error] = member.errors.full_messages.to_sentence
      end
      redirect_to edit_organization_admin_member_path(member)
    end

    def destroy
      partner = current_user.partner
      member = partner.users.find(params[:id])

      if member == current_user
        flash[:error] = "Vous ne pouvez pas vous retirer vous-même de l'organisation."
        return redirect_to edit_organization_admin_member_path(member)
      end

      if OrganizationAdminService.remove_member(author: current_user, member: member)
        flash[:success] = 'Membre retiré !'
        redirect_to organization_admin_members_path
      else
        pp member.errors
        flash[:error] = member.errors.full_messages.to_sentence.presence || 'Impossible de retirer le membre.'
        redirect_to edit_organization_admin_member_path(member)
      end
    end

    protected

    def ensure_can_edit_member!
      unless OrganizationAdmin::Permissions.can_edit_member?(current_user)
        render text: "Vous n'avez pas la permission de modifier un membre", status: :unauthorized
      end
    end

    def ensure_can_remove_member!
      unless OrganizationAdmin::Permissions.can_remove_member?(current_user)
        render text: "Vous n'avez pas la permission de retirer un membre", status: :unauthorized
      end
    end

    def member_params
      allowed_fields = [:first_name, :last_name, :email, :partner_role_title]
      allowed_fields += [:partner_admin] if OrganizationAdmin::Permissions.can_manage_admins?(current_user)
      params.require(:user).permit(allowed_fields)
    end
  end
end
