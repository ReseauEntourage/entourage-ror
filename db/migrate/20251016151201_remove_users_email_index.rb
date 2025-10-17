class RemoveUsersEmailIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :email, if_exists: true
  end
end
