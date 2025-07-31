class AddDeviceIdAndDeviceTypeToUser < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:users, :device_type)
      add_column :users, :device_type, :integer
    end

    add_column :users, :device_id, :string
  end
end
