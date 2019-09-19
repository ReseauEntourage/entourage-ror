class AddNotificationsPermissionsToUserApplications < ActiveRecord::Migration
  def change
    add_column :user_applications, :notifications_permissions, :string
  end
end
