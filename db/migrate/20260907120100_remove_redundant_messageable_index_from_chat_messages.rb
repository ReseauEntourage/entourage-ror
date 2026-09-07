class RemoveRedundantMessageableIndexFromChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_messages_on_messageable_id_and_messageable_type'

  # superseded by index_chat_messages_on_messageable_and_created_at
  # (messageable_type, messageable_id, created_at), whose leading columns
  # cover every messageable_id + messageable_type equality lookup in the app.

  def up
    # chat_messages is a multi-GB, high-write table: dropping a heavily-used
    # index concurrently can take longer than the app's default 2s
    # statement_timeout (config/database.yml), which migrations inherit
    execute "SET statement_timeout = '15min'"
    remove_index :chat_messages, column: [:messageable_id, :messageable_type],
      name: INDEX_NAME,
      algorithm: :concurrently
  ensure
    execute "RESET statement_timeout"
  end

  def down
    execute "SET statement_timeout = '15min'"
    add_index :chat_messages, [:messageable_id, :messageable_type],
      name: INDEX_NAME,
      algorithm: :concurrently
  ensure
    execute "RESET statement_timeout"
  end
end
