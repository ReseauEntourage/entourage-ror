class RemoveIndexFromJoinRequest < ActiveRecord::Migration
  def change
    remove_index :join_requests, [:user_id, :joinable_id]
    add_index :join_requests, [:user_id, :joinable_id]
  end
end
