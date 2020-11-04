class AddImageAndOnlineToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :image_url, :string
    add_column :entourages, :online, :boolean, default: false
    add_column :entourages, :event_url, :string
  end
end
