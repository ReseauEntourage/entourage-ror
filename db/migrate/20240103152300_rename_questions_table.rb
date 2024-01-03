class RenameQuestionsTable < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      ALTER TABLE questions RENAME TO old_questions;
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      ALTER TABLE old_questions RENAME TO questions;
    SQL

    execute(sql)
  end
end
