class AddDeviceFamilyToUserApplications < ActiveRecord::Migration
  def change
    add_column :user_applications, :device_family, :string
  end
end
