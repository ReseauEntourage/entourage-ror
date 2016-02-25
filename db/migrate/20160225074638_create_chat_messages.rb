class CreateChatMessages < ActiveRecord::Migration
  def change
    create_table :chat_messages do |t|
      t.integer :messageable_id,    null: false
      t.string  :messageable_type,  null: false
      t.text    :content,           null: false
      t.integer :user_id,           null: false

      t.timestamps                  null: false
    end

    add_index :chat_messages, [:messageable_id, :messageable_type]
    add_index :chat_messages, :user_id
  end
end
