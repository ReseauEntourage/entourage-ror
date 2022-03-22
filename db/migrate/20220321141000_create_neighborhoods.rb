class CreateNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    create_table :neighborhoods do |t|
      t.integer :user_id, null: false
      t.string :name, limit: 256
      t.string :description
      t.string :ethics
      t.string :photo_url
      t.float :latitude, null: false
      t.float :longitude, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :name
      t.index [:latitude, :longitude], name: :neighborhoods_coordinates
    end
  end

  def down
    remove_index :neighborhoods, :user_id
    remove_index :neighborhoods, :name
    remove_index :neighborhoods, :neighborhoods_coordinates

    drop_table :neighborhoods
  end
end

