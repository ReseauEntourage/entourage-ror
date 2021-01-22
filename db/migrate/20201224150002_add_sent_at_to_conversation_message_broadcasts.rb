class AddSentAtToConversationMessageBroadcasts < ActiveRecord::Migration
  def change
    add_column :conversation_message_broadcasts, :sent_at, :datetime
  end
end
