class AddIndexes < ActiveRecord::Migration
  def change
    add_index :users, :email
    add_index :user_partners, :user_id, where: '"default"'
  end
end
