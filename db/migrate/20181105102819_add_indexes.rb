class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :email
    add_index :user_partners, :user_id, where: '"default"'
  end
end
