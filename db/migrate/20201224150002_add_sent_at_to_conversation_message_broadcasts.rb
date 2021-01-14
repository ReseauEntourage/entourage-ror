class AddSentAtToConversationMessageBroadcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :conversation_message_broadcasts, :sent_at, :datetime
  end
end
