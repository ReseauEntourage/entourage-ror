class AddDeviceIdAndDeviceTypeToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :device_id, :string
    add_column :users, :device_type, :int
  end
end
