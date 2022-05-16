class AddImageUrlToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :chat_messages, :image_url, :string
  end

  def down
    remove_column :chat_messages, :image_url
  end
end
