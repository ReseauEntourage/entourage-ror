class DeleteSnapToRoad < ActiveRecord::Migration[4.2]
  def change
    drop_table :snap_to_road_tour_points
  end
end
