class CreateToursEntouragesView < ActiveRecord::Migration
  def up
    sql = <<-SQL
      CREATE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "type",
          user_id,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at
        FROM entourages

        UNION ALL

        SELECT
          distinct ON (id)
          id AS "feedable_id",
          'Tour' AS "feedable_type",
          CASE WHEN status=0 THEN 'ongoing' WHEN status=1 THEN 'closed' WHEN status=2 THEN 'freezed' END AS "status",
          '' AS "TITLE",
          tour_type as "type",
          user_id,
          tp.longitude,
          tp.latitude,
          number_of_people,
          created_at,
          updated_at
        FROM tours
        LEFT OUTER JOIN (
           SELECT latitude, longitude, tour_id
           from tour_points
        ) tp ON tp.tour_id = tours.id
        ORDER by feedable_id ASC
    SQL

    execute(sql)
  end

  def down
    execute('DROP VIEW feeds')
  end
end
