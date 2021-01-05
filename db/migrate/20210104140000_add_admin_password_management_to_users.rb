class AddAdminPasswordManagementToUsers < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_admin_password, :string
  end
end

