class ChangeIndexOnChatMessagesForConversationBroadcastId < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      DROP INDEX IF EXISTS chat_messages_conversation_message_broadcast_id;
    SQL

    execute <<-SQL
      CREATE INDEX index_chat_messages_on_conversation_broadcast_id
      ON chat_messages USING btree ((metadata ->> 'conversation_message_broadcast_id'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_chat_messages_on_conversation_broadcast_id;
    SQL

    execute <<-SQL
      CREATE INDEX chat_messages_conversation_message_broadcast_id
      ON chat_messages USING HASH ((metadata->'conversation_message_broadcast_id'));
    SQL
  end
end
