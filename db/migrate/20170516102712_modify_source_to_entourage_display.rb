class ModifySourceToEntourageDisplay < ActiveRecord::Migration[4.2]
  def change
    remove_column :entourage_displays, :source, :string
    add_column :entourage_displays, :source, :string, null: true, default: 'newsfeed'
  end
end
