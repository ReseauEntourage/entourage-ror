class CreateEntourageScores < ActiveRecord::Migration
  def change
    create_table :entourage_scores do |t|
      t.integer :entourage_id,  null: false
      t.integer :user_id,       null: false
      t.float :base_score,      null: false
      t.float :final_score,     null: false

      t.timestamps null: false
    end
    add_index :entourage_scores, :entourage_id

    add_column :entourage_displays, :user_id, :integer, null: false, index: true
  end
end
