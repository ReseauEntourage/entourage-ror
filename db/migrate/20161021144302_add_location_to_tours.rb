class AddLocationToTours < ActiveRecord::Migration
  def change
    add_column :tours, :latitude,  :float, null: true
    add_column :tours, :longitude, :float, null: true
    add_index :tours, [:latitude, :longitude]
  end
end
