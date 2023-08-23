class ChangeTravelDistanceDefaultAgain < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :travel_distance, :integer, default: 40
  end

  def down
    change_column :users, :travel_distance, :integer, default: 100
  end
end
