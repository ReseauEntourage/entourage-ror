class CreateAtdUsers < ActiveRecord::Migration
  def change
    create_table :atd_users do |t|
      t.integer :user_id,   null: true
      t.integer :atd_id,    null: false
      t.string :tel_hash,   null: true
      t.string :mail_hash,  null: true

      t.timestamps null: false
    end
    add_index :atd_users, [:atd_id, :user_id], unique: true
  end
end
