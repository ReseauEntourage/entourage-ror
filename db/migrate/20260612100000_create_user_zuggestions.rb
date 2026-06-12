class CreateUserZuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_zuggestions do |t|
      t.integer  :user_id,                null: false
      t.string   :suggestion_type,        null: false
      t.integer  :suggested_user_id
      t.integer  :suggested_entourage_id
      t.string   :suggested_action
      t.string   :reason,                 null: false
      t.string   :reason_type,            null: false
      t.datetime :actioned_at
      t.datetime :dismissed_at
      t.datetime :dismissed_until
      t.datetime :expires_at,             null: false

      t.timestamps
    end

    add_index :user_zuggestions, :user_id
    add_index :user_zuggestions, :suggested_user_id
    add_index :user_zuggestions, :suggested_entourage_id
    add_index :user_zuggestions, [:user_id, :suggestion_type]

    add_foreign_key :user_zuggestions, :users, column: :user_id
    add_foreign_key :user_zuggestions, :users, column: :suggested_user_id
    add_foreign_key :user_zuggestions, :entourages, column: :suggested_entourage_id
  end
end
