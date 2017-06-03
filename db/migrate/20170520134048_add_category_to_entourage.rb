class AddCategoryToEntourage < ActiveRecord::Migration
  def change
    add_column :entourages, :category, :string, null: true
  end
end
