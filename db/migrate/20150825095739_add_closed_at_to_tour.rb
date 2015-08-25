class AddClosedAtToTour < ActiveRecord::Migration
  def change
    add_column :tours, :closed_at, :timestamp
  end
end
