class AddIndexForFirstTourPoints < ActiveRecord::Migration[4.2]
  def change
    add_index :tour_points, [:tour_id, :id]
    add_index :tour_points, [:tour_id, :created_at]
  end
end
