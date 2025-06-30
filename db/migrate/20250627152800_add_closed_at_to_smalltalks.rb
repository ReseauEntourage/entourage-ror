class AddClosedAtToSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :smalltalks, :closed_at, :datetime, nullable: true
  end
end
