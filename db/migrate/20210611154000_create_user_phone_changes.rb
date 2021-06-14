class CreateUserPhoneChanges < ActiveRecord::Migration[4.2]
  def up
    create_table :user_phone_changes do |t|
      t.integer :user_id, null: false
      t.integer :admin_id
      t.string :kind, null: false
      t.string :phone_was, null: false
      t.string :phone, null: false
      t.string :email

      t.timestamps null: false

      t.index :user_id
      t.index :admin_id
      t.index :kind
    end
  end

  def down
    remove_index :user_phone_changes, :user_id
    remove_index :user_phone_changes, :admin_id
    remove_index :user_phone_changes, :kind

    drop_table :user_phone_changes
  end
end

