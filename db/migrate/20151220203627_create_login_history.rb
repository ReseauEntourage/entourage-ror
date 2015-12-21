class CreateLoginHistory < ActiveRecord::Migration
  def up
    create_table :login_histories do |t|
      t.integer :user_id,       null: false
      t.datetime :connected_at, null: false
    end

    execute <<-SQL
      CREATE UNIQUE INDEX index_login_histories_on_connected_at_by_hour
      ON login_histories(date_trunc('hour', connected_at), user_id);
    SQL
  end

  def down
    drop_table :login_histories
    execute <<-SQL
      DROP INDEX index_login_histories_on_connected_at_by_hour;
    SQL
  end
end
