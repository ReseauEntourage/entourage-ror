class AddAdminPinToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :admin_pin, :boolean, null: false, default: false
  end
end
