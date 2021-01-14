class AddIndexToPoisOnCategoryId < ActiveRecord::Migration[4.2]
  def change
    add_index :pois, [:category_id, :latitude, :longitude], where: :validated
  end
end
