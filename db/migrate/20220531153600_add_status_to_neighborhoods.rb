class AddStatusToNeighborhoods < ActiveRecord::Migration[5.2]
  def change
    add_column :neighborhoods, :status, :string, null: false, default: :active
  end
end
