class AddTitleToInappNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :inapp_notifications, :title, :string
  end

  def down
    remove_column :inapp_notifications, :title
  end
end

