class DeleteSnapToRoad < ActiveRecord::Migration
  def change
    drop_table :snap_to_road_tour_points
  end
end
