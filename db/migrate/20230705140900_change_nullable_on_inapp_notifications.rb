class ChangeNullableOnInappNotifications < ActiveRecord::Migration[6.1]
  def up
    change_column_null :inapp_notifications, :instance, true
  end

  def down
    change_column_null :inapp_notifications, :instance, false
  end
end

