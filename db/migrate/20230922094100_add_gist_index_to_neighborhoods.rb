class AddGistIndexToNeighborhoods < ActiveRecord::Migration[6.1]
  def up
    execute('create index index_neighborhoods_on_coordinates on neighborhoods using gist (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))')
  end

  def down
    execute('drop index index_neighborhoods_on_coordinates')
  end
end
