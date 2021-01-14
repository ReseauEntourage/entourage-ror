class CreateSessionHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :session_histories, id: false do |t|
      t.integer :user_id,  null: false
      t.date    :date,     null: false
      t.string  :platform, null: false
    end
    add_index :session_histories, [:user_id, :platform, :date], unique: true
  end
end
