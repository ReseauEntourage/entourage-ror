class RemoveUnblockAndOrganizationIdIndexes < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :unblock_at, if_exists: true
    remove_index :users, :organization_id, if_exists: true
  end
end
