class AddStatusToConversationMessageBroadcasts < ActiveRecord::Migration
  def change
    add_column :conversation_message_broadcasts, :status, :string, default: :draft, null: false
  end
end
