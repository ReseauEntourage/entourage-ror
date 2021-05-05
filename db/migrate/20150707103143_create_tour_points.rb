class CreateTourPoints < ActiveRecord::Migration[4.2]
  def change
    create_table :tour_points do |t|
      t.float :latitude
      t.float :longitude
      t.belongs_to :tour
      t.datetime :passing_time

      t.timestamps
    end
  end
end
