class AddStatusToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :chat_messages, :status, :string, default: :active
    add_column :chat_messages, :deleter_id, :integer
    add_column :chat_messages, :deleted_at, :datetime

    add_index :chat_messages, :status
  end

  def down
    remove_index :chat_messages, :status

    remove_column :chat_messages, :status
    remove_column :chat_messages, :deleter_id
    remove_column :chat_messages, :deleted_at
  end
end
