class AddMessageTypeIndexToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_index :chat_messages, :message_type
  end

  def down
    remove_index :chat_messages, :message_type
  end
end
