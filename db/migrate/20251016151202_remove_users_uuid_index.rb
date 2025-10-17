class RemoveUsersUuidIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :uuid, if_exists: true
  end
end
