class AddGistIndexToUserSmalltalks < ActiveRecord::Migration[6.1]
  def up
    execute("create index index_user_smalltalks_on_coordinates on user_smalltalks using gist (ST_SetSRID(ST_MakePoint(user_longitude, user_latitude), 4326))")
  end

  def down
    execute("drop index index_user_smalltalks_on_coordinates")
  end
end
