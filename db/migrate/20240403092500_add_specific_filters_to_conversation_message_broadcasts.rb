class AddSpecificFiltersToConversationMessageBroadcasts < ActiveRecord::Migration[6.1]
  def change
    add_column :conversation_message_broadcasts, :specific_filters, :jsonb, default: {}, null: false
  end
end
