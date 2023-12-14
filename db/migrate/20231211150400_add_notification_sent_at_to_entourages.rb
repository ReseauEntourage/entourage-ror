class AddNotificationSentAtToEntourages < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :notification_sent_at, :datetime, default: nil
  end
end
