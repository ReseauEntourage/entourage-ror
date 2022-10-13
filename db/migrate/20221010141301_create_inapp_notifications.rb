class CreateInappNotifications < ActiveRecord::Migration[5.2]
  def up
    create_table :inapp_notifications do |t|
      t.integer :user_id, null: false

      t.string :instance, null: false
      t.integer :instance_id

      t.datetime :completed_at
      t.datetime :skipped_at
      t.timestamps null: false

      t.index :user_id
      t.index :completed_at
      t.index :skipped_at
    end
  end

  def down
    remove_index :inapp_notifications, :user_id
    remove_index :inapp_notifications, :completed_at
    remove_index :inapp_notifications, :skipped_at

    drop_table :inapp_notifications
  end
end

