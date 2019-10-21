class AddIndexEncountersOnTourId < ActiveRecord::Migration
  def change
    add_index :encounters, :tour_id
  end
end
