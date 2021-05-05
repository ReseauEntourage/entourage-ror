class AddTourIdToEncounters < ActiveRecord::Migration[4.2]
  def change
    add_column :encounters, :tour_id, :integer
  end
end
