class ActivatePostgis < ActiveRecord::Migration[4.2]
  def up
    execute('CREATE EXTENSION IF NOT EXISTS postgis;')
  end

  def down
  end
end
