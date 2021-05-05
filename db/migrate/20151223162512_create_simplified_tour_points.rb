class CreateSimplifiedTourPoints < ActiveRecord::Migration[4.2]
  def change
    create_table :simplified_tour_points do |t|
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.integer :tour_id, null: false
    end

    add_index :simplified_tour_points, :tour_id
  end
end
