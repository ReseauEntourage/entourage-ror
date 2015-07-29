class AddVehicleTypeToTours < ActiveRecord::Migration
  def change
    add_column :tours, :vehicle_type, :integer, default: 0
  end
end
