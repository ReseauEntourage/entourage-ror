class CreateEvents < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      create type event_name as enum (
        'onboarding.profile.first_name.entered',
        'onboarding.chat_messages.welcome.sent',
        'onboarding.chat_messages.welcome.skipped'
      )
    SQL

    create_table :events, id: false do |t|
      t.integer  :user_id,           null: false
      t.column   :name, :event_name, null: false
      t.datetime :created_at,        null: false
    end

    add_index :events, [:user_id, :name], unique: true
  end

  def down
    drop_table :events
    execute %(drop type event_name)
  end
end
