class AddCompletedAtToSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :smalltalks, :completed_at, :datetime, nullable: true
  end
end
