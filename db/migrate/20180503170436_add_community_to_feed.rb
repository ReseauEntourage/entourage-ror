class AddCommunityToFeed < ActiveRecord::Migration
  def up
    sql = <<-SQL
      DROP VIEW IF EXISTS feeds;
      CREATE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "feed_type",
          concat(entourage_type, '_', coalesce(display_category, 'other')) as "feed_category",
          user_id,
          community,
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
          concat('tour_', tour_type) as "feed_category",
          user_id,
          'entourage' as "community",
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
      DROP VIEW IF EXISTS feeds;
      CREATE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "feed_type",
          concat(entourage_type, '_', coalesce(display_category, 'other')) as "feed_category",
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
          concat('tour_', tour_type) as "feed_category",
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
