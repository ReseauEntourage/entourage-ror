class AddPoiToOpenAgenda < ActiveRecord::Migration[7.1]
  def change
    add_column :open_agenda_sources, :poi_id, :integer
    add_index :open_agenda_sources, :poi_id

    add_column :open_agenda_events, :poi_id, :integer
    add_column :open_agenda_events, :latitude, :float
    add_column :open_agenda_events, :longitude, :float
    add_index :open_agenda_events, :poi_id
  end
end
