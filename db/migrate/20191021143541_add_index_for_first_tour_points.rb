class AddIndexForFirstTourPoints < ActiveRecord::Migration
  def change
    add_index :tour_points, [:tour_id, :id]
    add_index :tour_points, [:tour_id, :created_at]
  end
end
