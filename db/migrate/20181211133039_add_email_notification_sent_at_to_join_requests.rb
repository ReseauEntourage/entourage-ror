class AddEmailNotificationSentAtToJoinRequests < ActiveRecord::Migration
  def change
    add_column :join_requests, :email_notification_sent_at, :datetime
  end
end
