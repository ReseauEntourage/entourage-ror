class GeneralizeOpenAgendaToAssociationEvents < ActiveRecord::Migration[7.1]
  # Generalizes the OpenAgenda-only tables into a single, provider-agnostic pair
  # (association_event_sources / association_events) so a second source (HelloAsso)
  # can reuse the same table, admin CRUD and POI-matching logic — distinguished only
  # by the new `provider` column, mirroring how Poi already distinguishes
  # entourage/soliguide with a single `source` column instead of separate tables.
  def change
    rename_table :open_agenda_sources, :association_event_sources
    rename_table :open_agenda_events, :association_events

    rename_column :association_events, :open_agenda_source_id, :association_event_source_id
    rename_column :association_events, :source_event_uid, :source_uid
    # HelloAsso's external identifier (formSlug) is a string, unlike OpenAgenda's numeric uid.
    change_column :association_events, :source_uid, :string, null: false, using: 'source_uid::varchar'

    remove_index :association_events, column: [:association_event_source_id, :source_uid], name: 'index_open_agenda_events_on_source_and_uid'
    add_index :association_events, [:association_event_source_id, :source_uid], unique: true, name: 'index_association_events_on_source_and_uid'

    add_column :association_event_sources, :provider, :string, null: false, default: 'open_agenda'
    add_column :association_event_sources, :helloasso_organization_slug, :string
    add_index :association_event_sources, :provider
    add_index :association_event_sources, :helloasso_organization_slug, unique: true

    add_column :association_events, :provider, :string, null: false, default: 'open_agenda'
    add_index :association_events, :provider

    reversible do |dir|
      dir.up do
        execute "UPDATE association_event_sources SET provider = 'open_agenda'"
        execute "UPDATE association_events SET provider = 'open_agenda'"
      end
    end
  end
end
