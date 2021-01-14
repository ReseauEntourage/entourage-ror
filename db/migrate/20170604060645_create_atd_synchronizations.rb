class CreateAtdSynchronizations < ActiveRecord::Migration[4.2]
  def change
    create_table :atd_synchronizations do |t|
      t.string :filename, null: false

      t.timestamps null: false
    end
    add_index :atd_synchronizations, :filename, unique: true
  end
end
