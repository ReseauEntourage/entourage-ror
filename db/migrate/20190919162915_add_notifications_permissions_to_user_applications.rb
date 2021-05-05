class AddNotificationsPermissionsToUserApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :user_applications, :notifications_permissions, :string
  end
end
