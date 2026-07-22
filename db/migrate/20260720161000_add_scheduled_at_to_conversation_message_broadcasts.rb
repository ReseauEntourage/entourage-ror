class AddScheduledAtToConversationMessageBroadcasts < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_message_broadcasts, :scheduled_at, :datetime
  end
end
