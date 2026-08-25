class AddChatMessageIdToInappNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :inapp_notifications, :chat_message_id, :integer, default: nil
  end
end
