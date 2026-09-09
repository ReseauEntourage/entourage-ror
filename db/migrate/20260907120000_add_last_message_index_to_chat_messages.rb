class AddLastMessageIndexToChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_messages_on_messageable_and_created_at'

  def up
    # a previously interrupted CONCURRENTLY build can leave an invalid index
    # behind under this name, which would make CREATE INDEX fail
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"

    with_extended_statement_timeout do
      add_index :chat_messages, [:messageable_type, :messageable_id, :created_at],
        algorithm: :concurrently,
        name: INDEX_NAME
    end
  end

  def down
    with_extended_statement_timeout do
      remove_index :chat_messages, name: INDEX_NAME, algorithm: :concurrently
    end
  end

  private

  # chat_messages is a multi-GB, high-write table: building/dropping this
  # index concurrently can take longer than the connection's statement_timeout
  # (2s by default, 90s during the Heroku release phase - see Procfile).
  # RESET would not bring back that prior value: it falls back to Postgres's
  # own server/role default, ignoring whatever was SET earlier in the session.
  # So capture and restore the exact previous value instead.
  def with_extended_statement_timeout
    previous_timeout = execute('SHOW statement_timeout').first['statement_timeout']
    execute "SET statement_timeout = '15min'"
    yield
  ensure
    execute "SET statement_timeout = #{connection.quote(previous_timeout)}"
  end
end
