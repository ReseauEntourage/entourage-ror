class AddNotificationsPermissionsToSessionHistories < ActiveRecord::Migration
  def change
    add_column :session_histories, :notifications_permissions, :string, limit: 14
  end
end
