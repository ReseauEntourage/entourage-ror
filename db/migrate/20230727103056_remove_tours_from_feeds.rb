class RemoveToursFromFeeds < ActiveRecord::Migration[4.2]
  def up
    sql = <<-SQL
      DROP VIEW IF EXISTS feeds;
      CREATE VIEW feeds AS
        SELECT id AS "feedable_id",
          'Entourage' AS "feedable_type",
          status,
          title,
          entourage_type as "feed_type",
          case when group_type = 'action' then concat(entourage_type, '_', coalesce(display_category, 'other')) else group_type::text end as "feed_category",
          user_id,
          community,
          group_type,
          metadata,
          latitude,
          longitude,
          number_of_people,
          created_at,
          updated_at,
          feed_updated_at,
          online
        FROM entourages
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
        case when group_type = 'action' then concat(entourage_type, '_', coalesce(display_category, 'other')) else group_type::text end as "feed_category",
        user_id,
        community,
        group_type,
        metadata,
        latitude,
        longitude,
        number_of_people,
        created_at,
        updated_at,
        feed_updated_at,
        online
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
        'tour' as "group_type",
        '{}'::jsonb as metadata,
        latitude,
        longitude,
        number_of_people,
        created_at,
        updated_at,
        feed_updated_at,
        false as online
      FROM tours
    SQL

    execute(sql)
  end
end
