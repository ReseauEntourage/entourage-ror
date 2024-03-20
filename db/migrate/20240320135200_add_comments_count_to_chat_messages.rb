class AddCommentsCountToChatMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :chat_messages, :comments_count, :integer, default: 0
  end
end
