class AddPostIdToInappNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :inapp_notifications, :post_id, :integer, default: nil
  end

  def down
    remove_column :inapp_notifications, :post_id
  end
end
