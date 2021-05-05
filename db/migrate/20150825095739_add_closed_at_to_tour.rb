class AddClosedAtToTour < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :closed_at, :timestamp
  end
end
