class AddUuidToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :uuid, :uuid
    add_index  :entourages, :uuid, unique: true
  end
end
