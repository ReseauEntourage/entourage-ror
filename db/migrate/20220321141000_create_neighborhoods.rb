class CreateNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    create_table :neighborhoods do |t|
      t.integer :user_id, null: false
      t.string :name, limit: 256
      t.string :description
      t.string :ethics
      t.string :photo_url

      t.timestamps null: false

      t.index :user_id
      t.index :name
    end
  end

  def down
    remove_index :neighborhoods, :user_id
    remove_index :neighborhoods, :name

    drop_table :neighborhoods
  end
end

