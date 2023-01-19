class AddZoneToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :zone, :string, default: nil
    add_index :neighborhoods, :zone

    execute <<-SQL
      update neighborhoods set zone = 'departement' where is_departement = true;
    SQL

    if EnvironmentHelper.production?
      # id 51: voisins de nanterre
      # id 154: voisins de argenteuil
      # these neighborhoods have been created with a script
      execute <<-SQL
        update neighborhoods set zone = 'ville' where is_departement = false and id between 51 and 154;
      SQL
    elsif EnvironmentHelper.staging?
      # id 403: voisins de nanterre
      # id 506: voisins de argenteuil
      # these neighborhoods have been created with a script
      execute <<-SQL
        update neighborhoods set zone = 'ville' where is_departement = false and id between 403 and 506;
      SQL
    end
  end

  def down
    remove_index :neighborhoods, :zone
    remove_column :neighborhoods, :zone
  end
end
