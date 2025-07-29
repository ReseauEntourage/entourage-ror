class AddStatusToEntourageInvitation < ActiveRecord::Migration[4.2]
  def change
    add_column :entourage_invitations, :status, :string, null: false, default: 'pending'
  end
end
