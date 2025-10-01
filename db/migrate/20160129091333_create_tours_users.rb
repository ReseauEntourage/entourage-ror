class CreateToursUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :tours_users do |t|
      t.integer :user_id, null: false
      t.integer :tour_id, null: false
      t.string :status,   null: false, default: 'pending'

      t.timestamps null: false
    end

    add_index :tours_users, [:user_id, :tour_id], unique: true
  end
end
