class AddStatusChangedAtToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :status_changed_at, :datetime
  end

  def down
    remove_column :neighborhoods, :status_changed_at
  end
end

