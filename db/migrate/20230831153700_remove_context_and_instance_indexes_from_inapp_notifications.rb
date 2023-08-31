class RemoveContextAndInstanceIndexesFromInappNotifications < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      DROP INDEX IF EXISTS index_inapp_notifications_on_context
      DROP INDEX IF EXISTS index_inapp_notifications_on_instance
    SQL
  end

  def down
    add_index :inapp_notifications, :context
    add_index :inapp_notifications, :instance
  end
end
