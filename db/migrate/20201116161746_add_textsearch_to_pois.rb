class AddTextsearchToPois < ActiveRecord::Migration
  def change
    enable_extension :unaccent
    add_column :pois, :textsearch, :tsvector
    add_index  :pois, :textsearch, using: :gin
  end
end
