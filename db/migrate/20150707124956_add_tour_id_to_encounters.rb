class AddTourIdToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :tour_id, :integer
  end
end
