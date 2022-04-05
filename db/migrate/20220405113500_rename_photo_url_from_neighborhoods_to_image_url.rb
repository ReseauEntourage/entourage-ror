class RenamePhotoUrlFromNeighborhoodsToImageUrl < ActiveRecord::Migration[5.2]
  def up
    rename_column :neighborhoods, :photo_url, :image_url
  end

  def down
    rename_column :neighborhoods, :image_url, :photo_url
  end
end
