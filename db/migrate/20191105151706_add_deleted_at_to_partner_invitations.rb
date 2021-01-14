class AddDeletedAtToPartnerInvitations < ActiveRecord::Migration[4.2]
  def change
    add_column :partner_invitations, :deleted_at, :datetime
  end
end
