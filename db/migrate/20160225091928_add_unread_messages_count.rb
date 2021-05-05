class AddUnreadMessagesCount < ActiveRecord::Migration[4.2]
  def change
    add_column  :tours_users, :last_message_read, :datetime, null: true
    add_index   :chat_messages, :created_at
  end
end
