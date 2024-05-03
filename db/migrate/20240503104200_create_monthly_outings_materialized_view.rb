class CreateMonthlyOutingsMaterializedView < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      CREATE MATERIALIZED VIEW monthly_outings AS
        SELECT
          latitude,
          longitude,
          date_trunc('month', (metadata->>'starts_at')::timestamp) AS year_month_start

        FROM entourages

        WHERE group_type = 'outing'
          and (metadata->>'starts_at')::timestamp > (current_date - interval '1 year')
    SQL

    execute(sql)
  end

  def down
    execute('DROP MATERIALIZED VIEW monthly_outings')
  end
end
