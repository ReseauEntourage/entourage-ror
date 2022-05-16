class AddAncestryToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :chat_messages, :ancestry, :string
    add_index :chat_messages, :ancestry
  end

  def down
    remove_index :chat_messages, :ancestry
    remove_column :chat_messages, :ancestry, :string
  end
end
