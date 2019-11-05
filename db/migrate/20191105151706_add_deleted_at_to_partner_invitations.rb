class AddDeletedAtToPartnerInvitations < ActiveRecord::Migration
  def change
    add_column :partner_invitations, :deleted_at, :datetime
  end
end
