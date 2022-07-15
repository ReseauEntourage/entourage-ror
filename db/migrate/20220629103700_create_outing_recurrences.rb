class CreateOutingRecurrences < ActiveRecord::Migration[5.2]
  def up
    create_table :outing_recurrences do |t|
      t.string :identifier
      t.integer :recurrency
      t.boolean :continue

      t.timestamps null: false

      t.index :identifier, unique: true
    end
  end

  def down
    remove_index :outing_recurrences, :identifier

    drop_table :outing_recurrences
  end
end

