module OrganizationAdmin
  module Permissions
    def self.can_invite_member? inviter
      is_partner_admin?(inviter)
    end

    def self.can_edit_member? current_user
      is_partner_admin?(current_user)
    end

    def self.can_remove_member? current_user
      is_partner_admin?(current_user)
    end

    def self.can_manage_admins? current_user
      is_partner_admin?(current_user)
    end

    def self.can_edit_description? current_user
      is_partner_admin?(current_user)
    end

    def self.is_partner_admin? user
      user != nil && user.partner_admin?
    end
  end
end
