class AddDefaultToUser < ActiveRecord::Migration
  def change
    User.where("phone IS NULL OR organization_id IS NULL").destroy_all

    change_column :users, :manager,         :boolean, null: false, default: false
    change_column :users, :phone,           :string,  null: false
    change_column :users, :organization_id, :integer, null: false
  end
end
