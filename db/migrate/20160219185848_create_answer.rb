class CreateAnswer < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.integer :question_id, null: false
      t.string :value,        null: false
    end

    add_index :answers, :question_id
  end
end
