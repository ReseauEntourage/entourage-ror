class AddGeolocalizationFieldsToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :google_place_id, :string
    add_column :neighborhoods, :place_name, :string
    add_column :neighborhoods, :postal_code, :string

    add_index :neighborhoods, :postal_code
  end

  def down
    remove_index :neighborhoods, :postal_code

    remove_column :neighborhoods, :google_place_id
    remove_column :neighborhoods, :place_name
    remove_column :neighborhoods, :postal_code
  end
end
