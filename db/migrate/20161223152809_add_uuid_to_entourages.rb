class AddUuidToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :uuid, :uuid
    add_index  :entourages, :uuid, unique: true
  end
end
