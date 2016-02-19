class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :title,              null: false
      t.string :answer_type,        null: false
      t.string :answer_value,       null: false
      t.integer :organization_id,   null: false

      t.timestamps null: false
    end

    add_index :questions, :organization_id
  end
end
