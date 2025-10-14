class DeleteGcmRpushApps < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      DELETE FROM rpush_apps where type = 'Rpush::Client::ActiveRecord::Gcm::App';
    SQL

    execute(sql)
  end
end
