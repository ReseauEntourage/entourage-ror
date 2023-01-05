class AddSourceToPois < ActiveRecord::Migration[5.2]
  def up
    add_column :pois, :source, :integer, default: 0
    add_column :pois, :source_id, :integer, default: 0

    add_index :pois, :source_id
  end

  def down
    remove_index :pois, :source_id

    remove_column :pois, :source
    remove_column :pois, :source_id
  end
end

