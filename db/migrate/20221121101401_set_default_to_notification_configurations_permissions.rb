class SetDefaultToNotificationConfigurationsPermissions < ActiveRecord::Migration[5.2]
  def up
    change_column :notification_permissions, :permissions, :jsonb, null: false, default: {}
  end

  def down
    change_column :notification_permissions, :permissions, :jsonb
  end
end
