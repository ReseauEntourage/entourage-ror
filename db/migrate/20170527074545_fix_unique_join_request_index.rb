class FixUniqueJoinRequestIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :join_requests, [:user_id, :joinable_id]
    add_index :join_requests, [:user_id, :joinable_id, :joinable_type], name: 'index_join_requests_on_user_id_and_joinable_id'
  end
end
