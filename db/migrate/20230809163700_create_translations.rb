class CreateTranslations < ActiveRecord::Migration[6.1]
  def up
    create_table :translations do |t|
      t.integer :instance_id, null: false
      t.string :instance_type, null: false

      t.string :fr # french
      t.string :en # english
      t.string :de # deutsch
      t.string :pl # polish
      t.string :ro # romanian
      t.string :uk # ukrainian
      t.string :ar # arab

      t.timestamps null: false

      t.index [:instance_id, :instance_type]
    end
  end

  def down
    remove_index :translations, [:instance_id, :instance_type]

    drop_table :translations
  end
end

