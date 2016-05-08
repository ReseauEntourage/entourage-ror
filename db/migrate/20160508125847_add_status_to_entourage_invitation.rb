class AddStatusToEntourageInvitation < ActiveRecord::Migration
  def change
    add_column :entourage_invitations, :status, :string, null: false, default: "pending"
  end
end
