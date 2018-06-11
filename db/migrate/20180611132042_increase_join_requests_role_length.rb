class IncreaseJoinRequestsRoleLength < ActiveRecord::Migration
  def up
    change_column :join_requests, :role, :string, limit: 11
  end

  def down
    change_column :join_requests, :role, :string, limit: 8
  end
end
