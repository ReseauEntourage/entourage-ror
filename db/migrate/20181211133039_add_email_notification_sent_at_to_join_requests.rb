class AddEmailNotificationSentAtToJoinRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :join_requests, :email_notification_sent_at, :datetime
  end
end
