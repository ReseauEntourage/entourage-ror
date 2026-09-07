class RemoveRedundantMessageableIndexFromChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # superseded by index_chat_messages_on_messageable_and_created_at
    # (messageable_type, messageable_id, created_at), whose leading columns
    # cover every messageable_id + messageable_type equality lookup in the app.
    remove_index :chat_messages, column: [:messageable_id, :messageable_type],
      name: 'index_chat_messages_on_messageable_id_and_messageable_type',
      algorithm: :concurrently
  end
end
