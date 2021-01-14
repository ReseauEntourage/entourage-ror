class AddLengthToTour < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :length, :integer, default: 0
  end
end
