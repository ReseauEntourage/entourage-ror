class AddLocationToTours < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :latitude,  :float, null: true
    add_column :tours, :longitude, :float, null: true
    add_index :tours, [:latitude, :longitude]
  end
end
