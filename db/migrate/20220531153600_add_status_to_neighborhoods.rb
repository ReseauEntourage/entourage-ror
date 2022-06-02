class AddStatusToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :status, :string, null: false, default: :active
  end

  def down
    remove_column :neighborhoods, :status
  end
end
