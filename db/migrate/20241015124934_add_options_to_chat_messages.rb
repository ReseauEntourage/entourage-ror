class AddOptionsToChatMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :chat_messages, :options, :jsonb
  end
end
