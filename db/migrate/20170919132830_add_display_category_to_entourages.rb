class AddDisplayCategoryToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :display_category, :string
  end
end
