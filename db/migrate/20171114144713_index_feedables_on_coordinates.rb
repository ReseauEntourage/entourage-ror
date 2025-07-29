class IndexFeedablesOnCoordinates < ActiveRecord::Migration[4.2]
  def up
    execute('create index index_entourages_on_coordinates on entourages using gist (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))')
    execute('create index index_tours_on_coordinates      on tours      using gist (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))')
  end

  def down
    execute('drop index index_entourages_on_coordinates')
    execute('drop index index_tours_on_coordinates')
  end
end
