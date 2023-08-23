class ForceChangeTravelDistanceDefaultAgain < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      update users set travel_distance = 40 where travel_distance = 100;
    SQL
  end

  def down
    execute <<-SQL
      update users set travel_distance = 100 where travel_distance = 40;
    SQL
  end
end
