class ChangeJoinRequestConstraint < ActiveRecord::Migration
  def change
    remove_index :join_requests, ["user_id", "joinable_id"]
    add_index :join_requests, ["user_id", "joinable_id", "joinable_type"], name: "index_join_requests_on_user_and_joinable", unique: true
  end
end
