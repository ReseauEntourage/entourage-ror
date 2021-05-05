class AddPublicToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :public, :boolean, default: false
  end
end
