class CreateJoinTablePoiCategory < ActiveRecord::Migration
  def change
    create_join_table :pois, :categories, column_options: { null: true } do |t|
      t.index :poi_id
      t.index :category_id
    end
  end
end
