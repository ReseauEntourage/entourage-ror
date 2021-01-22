class AddAdminPinToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :admin_pin, :boolean, null: false, default: false
  end
end
