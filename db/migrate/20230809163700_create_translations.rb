class CreateTranslations < ActiveRecord::Migration[6.1]
  def up
    create_table :translations do |t|
      t.integer :instance_id, null: false
      t.integer :instance_type, null: false

      t.string :fr
      t.string :en

      t.timestamps null: false

      t.index [:instance_id, :instance_type]
    end
  end

  def down
    remove_index :translations, [:instance_id, :instance_type]

    drop_table :translations
  end
end

