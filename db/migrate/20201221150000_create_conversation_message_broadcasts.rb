class CreateConversationMessageBroadcasts < ActiveRecord::Migration
  def change
    create_table :conversation_message_broadcasts do |t|
      t.integer :moderation_area_id, null: false
      t.text :content, null: false
      t.string :goal, null: false
      t.string :title, null: false
      t.datetime :archived_at
      t.timestamps null: false

      t.index :moderation_area_id
      t.index :goal
    end
  end
end
