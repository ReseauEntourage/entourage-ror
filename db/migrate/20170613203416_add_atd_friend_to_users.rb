class AddAtdFriendToUsers < ActiveRecord::Migration
  def change
    add_column :users, :atd_friend, :boolean, null: false, default: false
  end
end
