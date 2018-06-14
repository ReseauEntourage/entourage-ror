class CreateEntourageDisplays < ActiveRecord::Migration
  def change
    create_table :entourage_displays do |t|
      t.integer :entourage_id
      t.float :distance
      t.integer :feed_rank

      t.timestamps null: false
    end

    add_index :entourage_displays, :entourage_id
  end
end
