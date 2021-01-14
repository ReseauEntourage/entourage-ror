class AddPasswordToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_password, :string
  end
end
