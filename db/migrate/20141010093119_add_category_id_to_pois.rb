class AddCategoryIdToPois < ActiveRecord::Migration[4.2]
  def change
  	remove_column :pois, :poi_type
  	add_column :pois, :category_id, :integer
  end
end
