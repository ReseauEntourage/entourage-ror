class AddSourceToEntourageDisplay < ActiveRecord::Migration
  def change
    add_column :entourage_displays, :source, :string, null: false, default: "newsfeed"
  end
end
