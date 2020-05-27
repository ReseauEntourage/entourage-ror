class CreatePartnerJoinRequests < ActiveRecord::Migration
  def change
    create_table :partner_join_requests do |t|
      t.integer :user_id, null: false
      t.integer :partner_id
      t.string :postal_code
      t.string :new_partner_name
      t.string :partner_role_title
      t.timestamps
    end
    add_index :partner_join_requests, :user_id
  end
end
