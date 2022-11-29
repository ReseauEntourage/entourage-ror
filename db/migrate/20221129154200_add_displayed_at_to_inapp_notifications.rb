class AddDisplayedAtToInappNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :inapp_notifications, :displayed_at, :datetime
    add_index :inapp_notifications, :displayed_at
  end

  def down
    remove_index :inapp_notifications, :displayed_at
    remove_column :inapp_notifications, :displayed_at
  end
end

