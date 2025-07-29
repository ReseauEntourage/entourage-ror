class RemoveInvitableTypeIndexesFromEntourageInvitations < ActiveRecord::Migration[5.2]
  def up
    remove_index :entourage_invitations, [:invitable_id, :invitable_type]
    remove_index :entourage_invitations, name: 'unique_invitation_by_entourage'

    add_index :entourage_invitations, :invitable_id
    add_index :entourage_invitations, [:inviter_id, :phone_number, :invitable_id], name: 'unique_invitation_by_entourage', unique: true
  end

  def down
    remove_index :entourage_invitations, :invitable_id
    remove_index :entourage_invitations, name: 'unique_invitation_by_entourage'

    add_index :entourage_invitations, [:invitable_id, :invitable_type]
    add_index :entourage_invitations, [:inviter_id, :phone_number, :invitable_id, :invitable_type], name: 'unique_invitation_by_entourage', unique: true
  end
end
