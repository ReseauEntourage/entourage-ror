class RemoveAdminPinToEntourages < ActiveRecord::Migration[6.1]
  def up
    remove_column :entourages, :admin_pin
  end

  def down
    add_column :entourages, :admin_pin, :boolean, null: false, default: false
  end
end
