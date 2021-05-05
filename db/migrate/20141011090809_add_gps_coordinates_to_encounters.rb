class AddGpsCoordinatesToEncounters < ActiveRecord::Migration[4.2]
  def change
    add_column :encounters, :latitude, :float
    add_column :encounters, :longitude, :float
  end
end
