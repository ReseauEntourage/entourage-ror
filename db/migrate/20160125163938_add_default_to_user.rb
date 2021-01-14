class AddDefaultToUser < ActiveRecord::Migration[4.2]
  def up
    change_column :users, :manager,         :boolean, null: false, default: false
    change_column :users, :phone,           :string,  null: false
    change_column :users, :organization_id, :integer, null: false
  end

  def down
    change_column :users, :manager,         :boolean
    change_column :users, :phone,           :string
    change_column :users, :organization_id, :integer
  end
end
