class AddNameToCategories < ActiveRecord::Migration[4.2]
  def change
  	add_column :categories, :name, :string
  end
end
