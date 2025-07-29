class AddStatusToPartnerInvitations < ActiveRecord::Migration[4.2]
  def up
    PartnerInvitation.delete_all
    add_column :partner_invitations, :status, :string, null: false
    remove_index :partner_invitations, [:partner_id, :invitee_email]
    remove_index :partner_invitations, [:partner_id, :invitee_id]
    add_index :partner_invitations, [:partner_id, :invitee_email], where: "status = 'pending'", unique: true, name: :index_pending_partner_invitations_on_partner_and_invitee_email
    add_index :partner_invitations, [:partner_id, :invitee_id], where: "status = 'accepted'", unique: true, name: :index_accepted_partner_invitations_on_partner_and_invitee_id
  end

  def down
    PartnerInvitation.delete_all
    remove_index :partner_invitations, name: :index_pending_partner_invitations_on_partner_and_invitee_email
    remove_index :partner_invitations, name: :index_accepted_partner_invitations_on_partner_and_invitee_id
    remove_column :partner_invitations, :status, :string, null: false
    add_index :partner_invitations, [:partner_id, :invitee_email], unique: true
    add_index :partner_invitations, [:partner_id, :invitee_id], where: 'accepted_at is not null', unique: true
  end
end
