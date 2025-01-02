class RemovePinToEntourages < ActiveRecord::Migration[6.1]
  def up
    remove_index  :entourages, :pin

    remove_column :entourages, :pin
    remove_column :entourages, :pins
  end

  def down
    add_column :entourages, :pin, :boolean, null: false, default: false
    add_column :entourages, :pins, :jsonb, default: [], null: false

    add_index  :entourages, :pin
  end
end
