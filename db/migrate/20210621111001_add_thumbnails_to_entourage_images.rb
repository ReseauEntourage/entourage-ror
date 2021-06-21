class AddThumbnailsToEntourageImages < ActiveRecord::Migration[5.1]
  def up
    add_column :entourage_images, :landscape_thumbnail_url, :string
    add_column :entourage_images, :portrait_thumbnail_url, :string
  end

  def down
    remove_column :entourages, :landscape_thumbnail_url
    remove_column :entourages, :portrait_thumbnail_url
  end
end
