class CreateConversationMessageBroadcasts < ActiveRecord::Migration
  def change
    create_table :conversation_message_broadcasts do |t|
      t.string :area, null: false
      t.text :content, null: false
      t.string :goal, null: false
      t.string :title, null: false
      t.datetime :archived_at
      t.timestamps null: false

      t.index :area
      t.index :goal
    end
  end
end
