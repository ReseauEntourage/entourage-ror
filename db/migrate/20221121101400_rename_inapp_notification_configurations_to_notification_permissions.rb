class RenameInappNotificationConfigurationsToNotificationPermissions < ActiveRecord::Migration[5.2]
  def up
    rename_table :inapp_notification_configurations, :notification_permissions
    rename_column :notification_permissions, :configuration, :permissions
  end

  def down
    rename_table :notification_permissions, :inapp_notification_configurations
    rename_column :notification_permissions, :permissions, :configuration
  end
end
