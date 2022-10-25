class AddStatusIndexToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_index :neighborhoods, :status
  end

  def down
    remove_index :neighborhoods, :status
  end
end
