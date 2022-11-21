class RenameInappNotificationConfigurationsToNotificationConfigurations < ActiveRecord::Migration[5.2]
  def up
    rename_table :inapp_notification_configurations, :notification_configurations
  end

  def down
    rename_table :notification_configurations, :inapp_notification_configurations
  end
end
