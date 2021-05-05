class AddStatusToTour < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :status, :integer, default: :ongoing
  end
end
