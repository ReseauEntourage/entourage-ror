class RenameInvitableTypeToInvitableTypeOldFromEntourageInvitations < ActiveRecord::Migration[5.2]
  def up
    change_column_null :entourage_invitations, :invitable_type, true
    rename_column :entourage_invitations, :invitable_type, :invitable_type_old
  end

  def down
    rename_column :entourage_invitations, :invitable_type_old, :invitable_type
    change_column_null :entourage_invitations, :invitable_type, false
  end
end
