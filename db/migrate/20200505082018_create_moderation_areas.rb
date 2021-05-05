class CreateModerationAreas < ActiveRecord::Migration[4.2]
  def change
    create_table :moderation_areas do |t|
      t.string  :departement,       limit: 2,  null: false
      t.string  :name,                         null: false
      t.integer :moderator_id
      t.text    :welcome_message_1
      t.text    :welcome_message_2
      t.string  :slack_channel,     limit: 80
    end
    add_index :moderation_areas, :departement, unique: true
  end
end
