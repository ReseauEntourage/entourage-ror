class CreateUserDenorms < ActiveRecord::Migration
  def up
    create_table :user_denorms do |t|
      t.integer :user_id, null: false

      t.integer :last_created_action_id
      t.integer :last_join_request_id
      t.integer :last_private_chat_message_id
      t.integer :last_group_chat_message_id

      t.timestamps null: false

      t.index :user_id
      t.index :last_created_action_id
      t.index :last_join_request_id
      t.index :last_private_chat_message_id
      t.index :last_group_chat_message_id
    end
  end

  def down
    drop_table :user_denorms
  end
end

