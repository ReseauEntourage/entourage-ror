class CopyAnnouncementsImagesPaths < ActiveRecord::Migration[5.1]
  def up
    add_column :announcements, :image_url_copy, :string
    add_column :announcements, :image_portrait_url_copy, :string

    execute <<-SQL
      update announcements set image_url_copy = image_url;
      update announcements set image_portrait_url_copy = image_portrait_url;
    SQL
  end

  def down
    execute <<-SQL
      update announcements set image_url = image_url_copy;
      update announcements set image_portrait_url = image_portrait_url_copy;
    SQL

    remove_column :announcements, :image_url_copy
    remove_column :announcements, :image_portrait_url_copy
  end
end

