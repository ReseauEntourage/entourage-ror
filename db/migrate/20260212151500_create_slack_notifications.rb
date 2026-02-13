class CreateSlackNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :slack_notifications do |t|
      t.integer :user_id
      t.string :context
      t.string :instance_type
      t.integer :instance_id
      t.jsonb :options

      t.timestamps null: false

      t.index :user_id
    end
  end
end
