class ActivatePostgis < ActiveRecord::Migration
  def up
    execute("CREATE EXTENSION IF NOT EXISTS postgis;")
  end

  def down
  end
end
