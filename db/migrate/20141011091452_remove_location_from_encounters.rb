class RemoveLocationFromEncounters < ActiveRecord::Migration[4.2]
  def change
    remove_column :encounters, :location
  end
end
