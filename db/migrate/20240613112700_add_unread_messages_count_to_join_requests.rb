class AddUnreadMessagesCountToJoinRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :join_requests, :unread_messages_count, :integer
  end
end
