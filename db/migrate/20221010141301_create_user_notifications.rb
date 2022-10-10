class CreateUserNotifications < ActiveRecord::Migration[5.2]
  def up
    create_table :user_notifications do |t|
      t.integer :user_id, null: false

      t.string :action, null: false
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
    remove_index :user_notifications, :user_id
    remove_index :user_notifications, :completed_at
    remove_index :user_notifications, :skipped_at

    drop_table :user_notifications
  end
end

