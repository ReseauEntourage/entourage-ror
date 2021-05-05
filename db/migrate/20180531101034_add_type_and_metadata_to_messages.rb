class AddTypeAndMetadataToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :chat_messages, :message_type, :string, limit: 20, default: 'text', null: false
    add_column :chat_messages, :metadata, :jsonb, default: {}, null: false
  end
end
