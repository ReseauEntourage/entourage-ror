class CreateEntourages < ActiveRecord::Migration[4.2]
  def change
    create_table :entourages do |t|
      t.string :status,               null: false, default: 'open'
      t.string :title,                null: false
      t.string :entourage_type,       null: false
      t.integer :user_id,             null: false
      t.float :latitude,              null: false
      t.float :longitude,             null: false
      t.integer :number_of_people,    null: false, default: 1

      t.timestamps null: false
    end

    add_index :entourages, :user_id
    add_index :entourages, [:latitude, :longitude]
  end
end
