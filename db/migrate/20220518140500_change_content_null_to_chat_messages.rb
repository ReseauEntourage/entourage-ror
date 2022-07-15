class ChangeContentNullToChatMessages < ActiveRecord::Migration[5.2]
  def up
    change_column_null :chat_messages, :content, true
  end

  def down
    change_column_null :chat_messages, :content, false
  end
end


