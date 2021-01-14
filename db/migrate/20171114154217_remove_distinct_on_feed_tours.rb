class RemoveDistinctOnFeedTours < ActiveRecord::Migration[4.2]
  def up
    sql = <<-SQL
      CREATE OR REPLACE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "feed_type",
          user_id,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at
        FROM entourages

        UNION ALL

        SELECT
          id AS "feedable_id",
          'Tour' AS "feedable_type",
          CASE WHEN status=0 THEN 'ongoing' WHEN status=1 THEN 'closed' WHEN status=2 THEN 'freezed' END AS "status",
          '' AS "TITLE",
          tour_type as "feed_type",
          user_id,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at
        FROM tours
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      CREATE OR REPLACE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "feed_type",
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
          tour_type as "feed_type",
          user_id,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at
        FROM tours
    SQL

    execute(sql)
  end
end
