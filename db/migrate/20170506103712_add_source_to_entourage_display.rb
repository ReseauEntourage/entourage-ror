class AddSourceToEntourageDisplay < ActiveRecord::Migration[4.2]
  def change
    add_column :entourage_displays, :source, :string, null: false, default: 'newsfeed'
  end
end
