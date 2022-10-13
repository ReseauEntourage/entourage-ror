class CreateInappNotificationConfigurations < ActiveRecord::Migration[5.2]
  def up
    create_table :inapp_notification_configurations do |t|
      t.integer :user_id, null: false
      t.jsonb :configuration

      t.index :user_id
    end
  end

  def down
    remove_index :inapp_notification_configurations, :user_id

    drop_table :inapp_notification_configurations
  end
end

