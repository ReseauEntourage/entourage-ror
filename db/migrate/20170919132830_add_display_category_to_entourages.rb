class AddDisplayCategoryToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :display_category, :string
  end
end
