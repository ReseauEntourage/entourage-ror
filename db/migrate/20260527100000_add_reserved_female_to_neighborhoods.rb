class AddReservedFemaleToNeighborhoods < ActiveRecord::Migration[7.1]
  def change
    add_column :neighborhoods, :reserved_female, :boolean, default: false, null: false
  end
end
