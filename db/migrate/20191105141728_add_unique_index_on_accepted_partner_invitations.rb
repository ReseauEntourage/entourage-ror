class AddUniqueIndexOnAcceptedPartnerInvitations < ActiveRecord::Migration[4.2]
  def change
    add_index :partner_invitations, [:partner_id, :invitee_id], where: 'accepted_at is not null', unique: true
  end
end
