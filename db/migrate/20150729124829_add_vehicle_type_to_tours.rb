class AddVehicleTypeToTours < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :vehicle_type, :integer, default: 0
  end
end
