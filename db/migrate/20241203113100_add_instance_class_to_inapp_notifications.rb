class AddInstanceClassToInappNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :inapp_notifications, :instance_baseclass, :string, default: 'Entourage'
  end
end
