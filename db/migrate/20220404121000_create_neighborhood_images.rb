class CreateNeighborhoodImages < ActiveRecord::Migration[5.2]
  def up
    create_table :neighborhood_images do |t|
      t.string :title
      t.string :image_url

      t.timestamps null: false
    end
  end

  def down
    drop_table :neighborhood_images
  end
end

