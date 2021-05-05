class AddIndexEncountersOnTourId < ActiveRecord::Migration[4.2]
  def change
    add_index :encounters, :tour_id
  end
end
