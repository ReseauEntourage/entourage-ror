class AddUniqueIndexes < ActiveRecord::Migration[4.2]
  def change
    User.where(phone: '').update_all(phone: nil)
    add_index :users, :email, unique: true
    add_index :users, :token, unique: true
    add_index :users, :phone, unique: true

    add_index :organizations, :name, unique: true
  end
end
