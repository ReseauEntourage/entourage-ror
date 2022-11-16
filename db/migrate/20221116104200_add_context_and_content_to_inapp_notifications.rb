class AddContextAndContentToInappNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :inapp_notifications, :context, :string
    add_column :inapp_notifications, :content, :string

    add_index :inapp_notifications, :context
  end

  def down
    remove_index :inapp_notifications, :context

    remove_column :inapp_notifications, :context
    remove_column :inapp_notifications, :content
  end
end
