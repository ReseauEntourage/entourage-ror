class AddAdminPartialIndexToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_users_on_id_where_admin'

  # Neighborhood#outings_with_admin_online looks admins up with
  # User.where(admin: true): without an index, Postgres scans every user
  # (~100 ms in production) to find about a hundred admins.
  def up
    # a previously interrupted CONCURRENTLY build can leave an invalid index
    # behind under this name, which would make CREATE INDEX fail
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"

    with_extended_statement_timeout do
      add_index :users, :id, where: 'admin', algorithm: :concurrently, name: INDEX_NAME
    end
  end

  def down
    with_extended_statement_timeout do
      remove_index :users, name: INDEX_NAME, algorithm: :concurrently
    end
  end

  private

  # users is read on every request: building the index concurrently waits for
  # running transactions and scans the table twice, which can exceed the
  # connection's statement_timeout (2s by default, 90s during the Heroku
  # release phase - see Procfile). Capture and restore the exact previous value.
  def with_extended_statement_timeout
    previous_timeout = execute('SHOW statement_timeout').first['statement_timeout']
    execute "SET statement_timeout = '15min'"
    yield
  ensure
    execute "SET statement_timeout = #{connection.quote(previous_timeout)}"
  end
end
