class AddAdminPasswordManagementToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_admin_password, :string
    add_column :users, :reset_admin_password_token, :string
    add_column :users, :reset_admin_password_sent_at, :datetime
  end
end

