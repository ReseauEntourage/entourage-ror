class AddLengthToTour < ActiveRecord::Migration
  def change
    add_column :tours, :length, :integer, default: 0
  end
end
