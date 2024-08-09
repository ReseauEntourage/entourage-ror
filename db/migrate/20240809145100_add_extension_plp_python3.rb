class AddExtensionPlpPython3 < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      -- CREATE EXTENSION plpython3u;
    SQL
  end

  def down
    execute <<-SQL
      DROP EXTENSION plpython3u;
    SQL
  end
end

