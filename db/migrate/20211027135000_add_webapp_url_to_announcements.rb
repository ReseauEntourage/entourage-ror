class AddWebappUrlToAnnouncements < ActiveRecord::Migration[5.2]
  def up
    add_column :announcements, :webapp_url, :string
  end

  def down
    remove_column :announcements, :webapp_url
  end
end
