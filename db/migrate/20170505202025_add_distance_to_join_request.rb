class AddDistanceToJoinRequest < ActiveRecord::Migration
  def change
    add_column :join_requests, :distance, :float, null: true
  end
end
