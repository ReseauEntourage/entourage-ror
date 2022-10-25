class ChangeDescriptionNullToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    change_column_null :neighborhoods, :description, true
  end

  def down
    change_column_null :neighborhoods, :description, false
  end
end


