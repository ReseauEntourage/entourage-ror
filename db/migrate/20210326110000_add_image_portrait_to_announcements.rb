class AddImagePortraitToAnnouncements < ActiveRecord::Migration
  def up
    add_column :announcements, :image_portrait_url, :string, default: nil
    add_index  :announcements, :image_portrait_url
  end

  def down
    remove_index  :announcements, :image_portrait_url
    remove_column :announcements, :image_portrait_url
  end
end
