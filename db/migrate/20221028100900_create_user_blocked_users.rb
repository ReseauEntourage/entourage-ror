class CreateUserBlockedUsers < ActiveRecord::Migration[5.2]
  def up
    create_table :user_blocked_users do |t|
      t.integer :user_id, null: false
      t.integer :blocked_user_id, null: false

      t.string :status, null: false, default: :blocked

      t.timestamps null: false

      t.index :user_id
      t.index :blocked_user_id
      t.index [:user_id, :blocked_user_id], unique: true
    end
  end

  def down
    remove_index :user_blocked_users, :user_id
    remove_index :user_blocked_users, :blocked_user_id
    remove_index [:user_id, :blocked_user_id], :blocked_user_id

    drop_table :user_blocked_users
  end
end

