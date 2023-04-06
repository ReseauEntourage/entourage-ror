class AddCountryToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :country, :string, default: :FR

    # not useful to add index: almost all neighborhoods are in France
  end

  def down
    remove_column :neighborhoods, :country
  end
end

