class AddCategoryIdToPois < ActiveRecord::Migration
  def change
  	remove_column :pois, :poi_type
  	add_column :pois, :category_id, :integer
  end
end
