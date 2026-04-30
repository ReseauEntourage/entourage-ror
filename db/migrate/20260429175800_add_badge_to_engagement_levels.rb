class AddBadgeToEngagementLevels < ActiveRecord::Migration[7.1]
  def up
    execute "DROP MATERIALIZED VIEW IF EXISTS engagement_levels CASCADE"

    execute <<~SQL
      CREATE MATERIALIZED VIEW engagement_levels AS
      WITH aggregated AS (
        SELECT
          CURRENT_DATE AS snapshot_date,
          user_id,

          COUNT(*) FILTER (
            WHERE engagement_type IN ('reaction', 'join_event', 'watch_resource')
          ) AS level_1_count,

          COUNT(*) FILTER (
            WHERE engagement_type IN ('post_message', 'post_action', 'join_groups', 'smalltalk')
          ) AS level_2_count,

          COUNT(*) FILTER (
            WHERE engagement_type IN ('post_group', 'create_group', 'create_action')
          ) AS level_3_count

        FROM denorm_daily_engagements_with_type
        WHERE date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY user_id
      )

      SELECT *,
        CASE
          WHEN level_3_count >= 2 THEN 'SUPER_ENGAGE'
          WHEN level_2_count >= 2 THEN 'ENGAGE'
          WHEN level_1_count >= 3 THEN 'OBSERVE'
          WHEN level_1_count >= 1 THEN 'PASSIVE'
          ELSE 'SILENT'
        END AS badge

      FROM aggregated;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX idx_engagement_levels_user
      ON engagement_levels (user_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP MATERIALIZED VIEW IF EXISTS engagement_levels;
    SQL
  end
end
