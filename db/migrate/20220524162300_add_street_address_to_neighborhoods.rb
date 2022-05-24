class AddStreetAddressToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :street_address, :string
  end

  def down
    remove_column :neighborhoods, :street_address
  end
end
