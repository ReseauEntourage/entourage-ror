class RemoveInstanceIdIndexFromInappNotifications < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      DROP INDEX IF EXISTS index_inapp_notifications_on_instance_id;
    SQL
  end

  def down
    add_index :inapp_notifications, :instance_id
  end
end
