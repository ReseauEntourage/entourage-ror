class RenameInvitableTypeToInvitableTypeOldFromEntourageInvitations < ActiveRecord::Migration[5.2]
  def up
    rename_column :entourage_invitations, :invitable_type, :invitable_type_old
  end

  def down
    rename_column :entourage_invitations, :invitable_type_old, :invitable_type
  end
end
