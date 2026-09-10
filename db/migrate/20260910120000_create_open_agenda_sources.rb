class CreateOpenAgendaSources < ActiveRecord::Migration[7.1]
  def change
    create_table :open_agenda_sources do |t|
      t.string :name, null: false
      # nullable: an agenda can be tracked before we've confirmed a UID for it (mirrors ical_feed_sources.url)
      t.integer :agenda_uid
      t.integer :partner_id
      t.string :city
      t.string :status, null: false, default: 'not_checked'
      t.datetime :last_checked_at
      t.datetime :last_synced_at
      t.text :last_error
      t.integer :upcoming_events_count, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :open_agenda_sources, :agenda_uid, unique: true
    add_index :open_agenda_sources, :partner_id
    add_index :open_agenda_sources, :status
    add_index :open_agenda_sources, :city

    create_table :open_agenda_events do |t|
      t.integer :open_agenda_source_id, null: false
      t.integer :source_event_uid, null: false
      t.string :title
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :location
      t.boolean :is_free
      t.string :organizer_name

      t.timestamps
    end

    add_index :open_agenda_events, [:open_agenda_source_id, :source_event_uid], unique: true, name: 'index_open_agenda_events_on_source_and_uid'
    add_index :open_agenda_events, :starts_at
  end
end
