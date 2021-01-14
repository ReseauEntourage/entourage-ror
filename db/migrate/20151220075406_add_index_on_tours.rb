class AddIndexOnTours < ActiveRecord::Migration[4.2]
  def change
    add_index :tour_points, [:tour_id, :latitude, :longitude]
    add_index :tours, [:user_id, :updated_at, :tour_type]
    add_index :users, :organization_id
  end
end
