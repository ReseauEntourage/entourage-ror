class IndexUsersOnCommunityAndRoles < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :roles, using: :gin
  end
end
