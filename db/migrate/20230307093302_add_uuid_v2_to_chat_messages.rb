class AddUuidV2ToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :chat_messages, :uuid_v2, :string, limit: 12

    ChatMessage.reset_column_information
    ChatMessage.find_each do |e|
      e.send :set_uuid
      e.save!
    end

    change_column :chat_messages, :uuid_v2, :string, limit: 12, null: false

    add_index :chat_messages, :uuid_v2, unique: true
  end

  def down
    remove_index :chat_messages, :uuid_v2

    remove_column :chat_messages, :uuid_v2
  end
end
