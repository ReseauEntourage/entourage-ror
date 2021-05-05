class AddUserIdToTour < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :user_id, :integer
  end
end
