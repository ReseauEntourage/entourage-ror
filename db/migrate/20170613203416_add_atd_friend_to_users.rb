class AddAtdFriendToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :atd_friend, :boolean, null: false, default: false
  end
end
