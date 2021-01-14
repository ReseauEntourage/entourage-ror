class AddDeviceFamilyToUserApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :user_applications, :device_family, :string
  end
end
