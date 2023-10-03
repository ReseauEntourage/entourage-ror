class AddNeighborhoodScopeToConversationMessageBroadcasts < ActiveRecord::Migration[6.1]
  def change
    add_column :conversation_message_broadcasts, :conversation_type, :string, default: "Entourage"
    add_column :conversation_message_broadcasts, :conversation_ids, :json, default: {}
    rename_column :conversation_message_broadcasts, :sent_users_count, :sent_recipients_count

    add_index :conversation_message_broadcasts, :conversation_type
  end
end
