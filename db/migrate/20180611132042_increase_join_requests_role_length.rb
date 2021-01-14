class IncreaseJoinRequestsRoleLength < ActiveRecord::Migration[4.2]
  def up
    change_column :join_requests, :role, :string, limit: 11
  end

  def down
    change_column :join_requests, :role, :string, limit: 8
  end
end
