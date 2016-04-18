class CreateEntourageInvitations < ActiveRecord::Migration
  def change
    create_table :entourage_invitations do |t|
      t.integer :invitable_id,    null: false
      t.string  :invitable_type,  null: false
      t.integer :inviter_id,      null: false
      t.integer :invitee_id,      null: true
      t.string  :invitation_mode, null: false
      t.string  :phone_number,    null: false

      t.timestamps null: false
    end

    add_index :entourage_invitations, :phone_number
    add_index :entourage_invitations, :inviter_id
    add_index :entourage_invitations, :invitee_id
    add_index :entourage_invitations, [:invitable_id, :invitable_type]
  end
end
