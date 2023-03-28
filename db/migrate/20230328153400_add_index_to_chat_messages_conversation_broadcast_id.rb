class AddIndexToChatMessagesConversationBroadcastId < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE INDEX chat_messages_conversation_message_broadcast_id ON chat_messages USING HASH ((metadata->'conversation_message_broadcast_id'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX chat_messages_conversation_message_broadcast_id;
    SQL
  end
end
