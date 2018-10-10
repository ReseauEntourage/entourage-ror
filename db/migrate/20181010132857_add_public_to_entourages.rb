class AddPublicToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :public, :boolean, default: false
  end
end
