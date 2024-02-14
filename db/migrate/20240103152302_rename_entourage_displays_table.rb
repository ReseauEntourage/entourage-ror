class RenameEntourageDisplaysTable < ActiveRecord::Migration[6.1]
  def up
    return if EnvironmentHelper.staging? # table already deleted

    sql = <<-SQL
      ALTER TABLE entourage_displays RENAME TO old_entourage_displays;
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      ALTER TABLE old_entourage_displays RENAME TO entourage_displays;
    SQL

    execute(sql)
  end
end
