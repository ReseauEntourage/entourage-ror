class AddUsersLastSignInAtIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :last_sign_in_at, name: :index_users_last_sign_in_at, where: "last_sign_in_at is not null"
  end
end
