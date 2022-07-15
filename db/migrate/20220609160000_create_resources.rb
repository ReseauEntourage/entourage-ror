class CreateResources < ActiveRecord::Migration[5.2]
  def up
    create_table :resources do |t|
      t.string :name, limit: 256, null: false
      t.string :category, limit: 32, null: false, default: :all
      t.string :description
      t.string :image_url
      t.string :url

      t.timestamps null: false

      t.index :name
    end
  end

  def down
    remove_index :resources, :name

    drop_table :resources
  end
end
