class CreateEntouragesUsers < ActiveRecord::Migration
  def change
    create_table :entourages_users do |t|
      t.integer :user_id,       null: false
      t.integer :entourage_id,  null: false

      t.timestamps null: false
    end

    add_index :entourages_users, [:user_id, :entourage_id]
  end
end
