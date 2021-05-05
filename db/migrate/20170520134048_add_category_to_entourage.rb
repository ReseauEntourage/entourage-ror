class AddCategoryToEntourage < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :category, :string, null: true
  end
end
