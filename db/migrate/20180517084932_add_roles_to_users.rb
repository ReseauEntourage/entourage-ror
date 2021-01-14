class AddRolesToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :roles, :jsonb, default: [], null: false
  end
end
