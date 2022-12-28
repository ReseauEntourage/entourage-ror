class AddHasImageUrlToEntourageDenorms < ActiveRecord::Migration[5.2]
  def up
    add_column :entourage_denorms, :has_image_url, :boolean, default: false
  end

  def down
    remove_column :entourage_denorms, :has_image_url
  end
end
