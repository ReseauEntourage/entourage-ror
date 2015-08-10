class AddUserIdToTour < ActiveRecord::Migration
  def change
    add_column :tours, :user_id, :integer
  end
end
