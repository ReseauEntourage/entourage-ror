class AddPublicToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :public, :boolean, default: true
  end

  def down
    remove_column :neighborhoods, :public
  end
end

