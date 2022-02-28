class AddTravelDistanceToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :travel_distance, :integer, default: 10
  end

  def down
    remove_column :users, :travel_distance
  end
end
