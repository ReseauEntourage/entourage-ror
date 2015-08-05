class AddDeviceIdAndDeviceTypeToUser < ActiveRecord::Migration
  def change
    add_column :users, :device_id, :string
    add_column :users, :device_type, :int
  end
end
