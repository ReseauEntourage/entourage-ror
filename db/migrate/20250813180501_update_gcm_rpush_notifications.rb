class UpdateGcmRpushNotifications < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      UPDATE rpush_notifications
      SET type = 'Rpush::Client::ActiveRecord::Fcm::Notification'
      WHERE type = 'Rpush::Client::ActiveRecord::Gcm::Notification';
    SQL

    execute(sql)
  end
end
