class CreatePartnerInvitations < ActiveRecord::Migration
  def change
    create_table :partner_invitations do |t|
      t.integer  :partner_id,         null: false
      t.integer  :inviter_id,         null: false
      t.string   :invitee_email,      null: false
      t.string   :invitee_name
      t.string   :invitee_role_title
      t.integer  :invitee_id
      t.string   :token,              null: false
      t.datetime :invited_at,         null: false
      t.datetime :accepted_at
    end

    add_index :partner_invitations, [:partner_id, :invitee_email], unique: true
    add_index :partner_invitations, :token, unique: true
  end
end
