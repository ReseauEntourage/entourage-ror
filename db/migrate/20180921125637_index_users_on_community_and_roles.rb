class IndexUsersOnCommunityAndRoles < ActiveRecord::Migration
  def change
    add_index :users, :roles, using: :gin
  end
end
