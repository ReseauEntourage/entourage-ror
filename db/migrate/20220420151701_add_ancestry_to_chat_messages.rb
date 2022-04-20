class AddAncestryToChatMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :chat_messages, :ancestry, :string
    add_index :chat_messages, :ancestry
  end
end
