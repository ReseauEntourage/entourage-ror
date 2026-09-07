class AddLastMessageIndexToChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :chat_messages, [:messageable_type, :messageable_id, :created_at],
      algorithm: :concurrently,
      name: 'index_chat_messages_on_messageable_and_created_at'
  end
end
