class AddIsDepartementToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :is_departement, :boolean, default: false
  end

  def down
    remove_column :neighborhoods, :is_departement
  end
end

