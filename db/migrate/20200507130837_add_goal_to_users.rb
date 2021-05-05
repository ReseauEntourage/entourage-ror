class AddGoalToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :goal, :string
  end
end
