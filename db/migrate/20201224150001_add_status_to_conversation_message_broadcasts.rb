class AddStatusToConversationMessageBroadcasts < ActiveRecord::Migration
  def change
    add_column :conversation_message_broadcasts, :status, :string, default: :draft, null: false

    add_index  :conversation_message_broadcasts, :status
  end
end
