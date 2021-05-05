class AddMetadataToEntourageInvitations < ActiveRecord::Migration[4.2]
  def change
    add_column :entourage_invitations, :metadata, :jsonb, default: {}, null: false
  end
end
