class AddStatusToConversationMessageBroadcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :conversation_message_broadcasts, :status, :string, default: :draft, null: false

    add_index  :conversation_message_broadcasts, :status
  end
end
