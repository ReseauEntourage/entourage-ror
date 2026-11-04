class CreateUserStats < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:user_stats)

    create_table :user_stats do |t|
      t.integer :user_id, null: false
      t.integer :action_creations_count, default: 0, null: false
      t.integer :neighborhood_messages_count, default: 0, null: false
      t.integer :conversation_members_count, default: 0, null: false
      t.timestamps
    end

    add_index :user_stats, :user_id, unique: true, name: "index_user_stats_on_user_id"
  end
end
