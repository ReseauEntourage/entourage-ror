class AddIndexToPoisOnCategoryId < ActiveRecord::Migration
  def change
    add_index :pois, [:category_id, :latitude, :longitude], where: :validated
  end
end
