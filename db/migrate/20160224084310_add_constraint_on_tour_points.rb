class AddConstraintOnTourPoints < ActiveRecord::Migration
  def change
    change_column :tour_points, :latitude,      :float,     null: false
    change_column :tour_points, :longitude,     :float,     null: false
    change_column :tour_points, :tour_id,       :integer,   null: false
    change_column :tour_points, :passing_time,  :datetime,  null: false
  end
end
