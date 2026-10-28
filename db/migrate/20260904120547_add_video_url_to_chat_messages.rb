class AddVideoUrlToChatMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_messages, :video_url, :string
  end
end
