class CreateOptions < ActiveRecord::Migration[5.2]
  def up
    create_table :options do |t|
      t.string :key, null: false
      t.string :description
      t.boolean :active, default: true

      t.timestamps null: false

      t.index :key
    end
  end

  def down
    remove_index :options, :key

    drop_table :options
  end
end

