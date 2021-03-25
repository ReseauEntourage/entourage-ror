class AddCategoryToAnnouncements < ActiveRecord::Migration
  def up
    add_column :announcements, :category, :string, default: nil
    add_index  :announcements, :category
  end

  def down
    remove_index  :announcements, :category
    remove_column :announcements, :category
  end
end
