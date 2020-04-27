class AddMetadataToEntourageInvitations < ActiveRecord::Migration
  def change
    add_column :entourage_invitations, :metadata, :jsonb, default: {}, null: false
  end
end
