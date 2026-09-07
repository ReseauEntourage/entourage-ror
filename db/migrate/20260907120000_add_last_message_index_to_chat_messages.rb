class AddLastMessageIndexToChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_messages_on_messageable_and_created_at'

  def up
    # a previously interrupted CONCURRENTLY build can leave an invalid index
    # behind under this name, which would make CREATE INDEX fail
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"

    # chat_messages is a multi-GB, high-write table: building this index
    # concurrently takes longer than the app's default 2s statement_timeout
    # (config/database.yml), which migrations otherwise inherit
    execute "SET statement_timeout = '15min'"
    add_index :chat_messages, [:messageable_type, :messageable_id, :created_at],
      algorithm: :concurrently,
      name: INDEX_NAME
  ensure
    execute "RESET statement_timeout"
  end

  def down
    execute "SET statement_timeout = '15min'"
    remove_index :chat_messages, name: INDEX_NAME, algorithm: :concurrently
  ensure
    execute "RESET statement_timeout"
  end
end
