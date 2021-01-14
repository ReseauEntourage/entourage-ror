class CreateUserNewsfeeds < ActiveRecord::Migration[4.2]
  def change
    create_table :user_newsfeeds do |t|
      t.integer :user_id, null: false
      t.float :latitude,  null: false
      t.float :longitude, null: false

      t.timestamps null: false
    end
    add_index :user_newsfeeds, :user_id
  end
end
