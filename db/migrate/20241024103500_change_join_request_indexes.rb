class ChangeJoinRequestIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :join_requests, :confirmed_at
    remove_index :join_requests, [:joinable_type, :joinable_id, :status]

    add_index :join_requests, [:joinable_type, :joinable_id]
    add_index :join_requests, :user_id

    rename_index :join_requests, "index_join_requests_on_user_id_and_joinable_id", "index_join_requests_on_user_id_and_joinable"
  end
end
