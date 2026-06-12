class CreateUserSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_suggestions do |t|
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

    add_index :user_suggestions, :user_id
    add_index :user_suggestions, :suggested_user_id
    add_index :user_suggestions, :suggested_entourage_id
    add_index :user_suggestions, [:user_id, :suggestion_type]

    add_foreign_key :user_suggestions, :users, column: :user_id
    add_foreign_key :user_suggestions, :users, column: :suggested_user_id
    add_foreign_key :user_suggestions, :entourages, column: :suggested_entourage_id
  end
end
