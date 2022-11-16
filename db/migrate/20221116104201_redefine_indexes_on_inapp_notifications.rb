class RedefineIndexesOnInappNotifications < ActiveRecord::Migration[5.2]
  def up
    remove_index :inapp_notifications, :completed_at
    remove_index :inapp_notifications, :skipped_at

    add_index :inapp_notifications, :instance
    add_index :inapp_notifications, :instance_id
  end

  def down
    add_index :inapp_notifications, :completed_at
    add_index :inapp_notifications, :skipped_at

    remove_index :inapp_notifications, :instance
    remove_index :inapp_notifications, :instance_id
  end
end
