class DropSuggestionComputeHistories < ActiveRecord::Migration[4.2]
  def up
    drop_table :suggestion_compute_histories
  end

  def down
    create_table :suggestion_compute_histories do |t|
      t.integer :user_number,             null: false
      t.integer :total_user_number,       null: false
      t.integer :entourage_number,        null: false
      t.integer :total_entourage_number,  null: false
      t.integer :duration,                null: false
      t.string :filter_type,              null: false, default: 'NORMAL'

      t.timestamps null: false
    end
  end
end
