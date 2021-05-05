class AddDistanceToJoinRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :join_requests, :distance, :float, null: true
  end
end
