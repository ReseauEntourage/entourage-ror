class AddStatusToTour < ActiveRecord::Migration
  def change
    add_column :tours, :status, :integer, default: :ongoing
  end
end
