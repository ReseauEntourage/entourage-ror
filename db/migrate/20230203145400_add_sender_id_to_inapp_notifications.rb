class AddSenderIdToInappNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :inapp_notifications, :sender_id, :integer
  end

  def down
    remove_column :inapp_notifications, :sender_id
  end
end

