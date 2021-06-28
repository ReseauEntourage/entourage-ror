class AddSuperAdminToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :super_admin, :boolean, default: false
  end

  def down
    remove_column :users, :super_admin
  end
end
