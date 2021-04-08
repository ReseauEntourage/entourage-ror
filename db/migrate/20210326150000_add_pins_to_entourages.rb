class AddPinsToEntourages < ActiveRecord::Migration[4.2]
  def up
    add_column :entourages, :pin, :boolean, default: false
    add_column :entourages, :pins, :jsonb, default: [], null: false

    add_index  :entourages, :pin
  end

  def down
    remove_index  :entourages, :pin

    remove_column :entourages, :pin
    remove_column :entourages, :pins
  end
end
