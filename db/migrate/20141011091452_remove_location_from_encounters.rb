class RemoveLocationFromEncounters < ActiveRecord::Migration
  def change
    remove_column :encounters, :location
  end
end
