class RefreshMonthlyOutingsMaterializedView < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      REFRESH MATERIALIZED VIEW monthly_outings
    SQL

    execute(sql)
  end
end
