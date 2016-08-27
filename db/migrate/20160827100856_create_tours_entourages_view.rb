class CreateToursEntouragesView < ActiveRecord::Migration
  def up
    sql = <<-SQL
      CREATE VIEW tours_entourages AS
        SELECT id,
          status,
          title,
          entourage_type,
          user_id,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at
        FROM entourages

        UNION ALL

        SELECT id,
          '0' AS "status",
          '' AS "TITLE",
          tour_type,
          user_id,
          0 AS "latitude",
          0 AS "longitude",
          number_of_people,
          created_at,
          updated_at
        FROM tours
    SQL

    execute(sql)
  end

  def down
    execute('DROP VIEW tours_entourages')
  end
end
