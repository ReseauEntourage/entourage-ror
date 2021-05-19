class CreateEntourageImages < ActiveRecord::Migration[5.1]
  def up
    create_table :entourage_images do |t|
      t.string :title
      t.string :landscape_url
      t.string :portrait_url

      t.timestamps null: false
    end
  end

  def down
    drop_table :entourage_images
  end
end

