class AddGpsCoordinatesToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :latitude, :float
    add_column :encounters, :longitude, :float
  end
end
