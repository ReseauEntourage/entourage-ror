class DropAdminUsers < ActiveRecord::Migration[4.2]
  def up
    drop_table :admin_users
    add_column :users, :admin, :boolean, default: false, null: false
  end

  def down
    create_table(:admin_users) do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''
    end
    remove_column :users, :admin
  end
end
