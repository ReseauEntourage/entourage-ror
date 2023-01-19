class RemoveIsDepartementFromNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    remove_column :neighborhoods, :is_departement
  end

  def down
    add_column :neighborhoods, :is_departement, :boolean, default: false

    execute <<-SQL
      update neighborhoods set is_departement = true where zone = 'departement';
    SQL
  end
end
