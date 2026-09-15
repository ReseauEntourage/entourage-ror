# Reproduces, verbatim in spirit, the `user_segments` CTE from Metabase
# question 2495 (sub-segment breakdown: question 2499) — these Metabase
# questions are the source of truth for this classification. Any future
# change to them should be mirrored here; this file should not drift from
# them the way the older `engagement_levels` materialized view already has.
#
# Engagement-type buckets (counted over the trailing 30 days):
#   N1 (light):  reaction, watch_resource, join_groups, survey
#   N2 (medium): post_message, smalltalk, post_group
#   N3 (strong): create_group, create_action, join_event
#
# `survey` corresponds to a poll (`surveys`), answered per user via
# `survey_responses`, tied to a given `chat_message`.
#
# Classification order matters (Pilier is evaluated before Contributeur):
#   1. <= 1 lifetime session AND N1+N2+N3 = 0  -> unclassified (nil)
#   2. N1+N2+N3 = 0                            -> Silencieux
#   3. N1 >= 1 AND N2 = 0 AND N3 = 0           -> Curieux
#   4. N2 = 1 AND N3 = 0                       -> Observateur
#   5. N3 >= 2                                 -> Pilier
#   6. N2 >= 2 OR N3 = 1                       -> Contributeur
#
# "Session" here is a count of `session_histories` rows up to `as_of` (no
# platform dedup) - matches the Metabase reference exactly when `as_of` is
# today.
#
# Eligibility: signed in within the 30 days up to `as_of`, not deleted, and
# not a `team`-targeted user. `targeting_profile IS NULL` counts as
# eligible - a plain `!= 'team'` would silently exclude every user with no
# profile set, since SQL's three-valued logic makes `NULL != 'team'`
# evaluate to NULL, not TRUE.
#
# `eligibility:` picks how "signed in in the last 30 days" is determined:
#   :last_sign_in_at  - reads `users.last_sign_in_at` directly. Exact match
#                       to the Metabase reference, but `last_sign_in_at`
#                       only ever holds its *current* value - this mode is
#                       only meaningful when `as_of` is today.
#   :login_histories  - reconstructs it from `login_histories` (a real
#                       per-login event log) instead, for a past `as_of`
#                       date. This is an approximation of the live rule,
#                       not the rule itself: `login_histories` is the best
#                       available substitute for a column that isn't
#                       historized. Used by EngagementSegmentBackfillJob.
#
# Whichever mode is used, `as_of` in the past cannot recover historical
# `targeting_profile`/`deleted` values either - neither is historized -
# so a backfill applies *today's* values across the whole reconstructed
# period. This is a known, accepted approximation: both rarely change.
class EngagementSegmentComputation
  Result = Struct.new(:user_id, :segment, :sub_segment)

  def self.call(as_of: Date.current, eligibility: :last_sign_in_at)
    ActiveRecord::Base.connection.exec_query(sql(as_of: as_of, eligibility: eligibility)).map do |row|
      Result.new(row["user_id"], row["segment"], row["sub_segment"])
    end
  end

  def self.sql(as_of:, eligibility:)
    as_of_sql = ActiveRecord::Base.connection.quote(as_of)

    <<~SQL
      WITH user_actions AS (
        SELECT
          user_id,
          COUNT(CASE WHEN engagement_type IN ('reaction', 'watch_resource', 'join_groups', 'survey') THEN 1 END) AS n1_count,
          COUNT(CASE WHEN engagement_type IN ('post_message', 'smalltalk', 'post_group') THEN 1 END)              AS n2_count,
          COUNT(CASE WHEN engagement_type IN ('create_group', 'create_action', 'join_event') THEN 1 END)          AS n3_count
        FROM denorm_daily_engagements_with_type
        WHERE date >= #{as_of_sql}::date - INTERVAL '30 days'
          AND date <= #{as_of_sql}::date
        GROUP BY user_id
      ),
      user_actions_alltime AS (
        SELECT DISTINCT user_id
        FROM denorm_daily_engagements_with_type
        WHERE date < #{as_of_sql}::date - INTERVAL '30 days'
      ),
      user_sessions AS (
        SELECT user_id, COUNT(*) AS nb_sessions
        FROM session_histories
        WHERE date <= #{as_of_sql}::date
        GROUP BY user_id
      ),
      all_users AS (
        SELECT DISTINCT id AS user_id
        FROM users
        WHERE #{eligibility_clause(as_of_sql, eligibility)}
          AND (targeting_profile != 'team' OR targeting_profile IS NULL)
          AND deleted IS FALSE
      )
      SELECT
        u.user_id,
        CASE
          WHEN COALESCE(s.nb_sessions, 0) <= 1
            AND COALESCE(a.n1_count, 0) + COALESCE(a.n2_count, 0) + COALESCE(a.n3_count, 0) = 0
            THEN NULL
          WHEN COALESCE(a.n1_count, 0) + COALESCE(a.n2_count, 0) + COALESCE(a.n3_count, 0) = 0
            THEN 'Silencieux'
          WHEN COALESCE(a.n1_count, 0) >= 1
            AND COALESCE(a.n2_count, 0) = 0
            AND COALESCE(a.n3_count, 0) = 0
            THEN 'Curieux'
          WHEN COALESCE(a.n2_count, 0) = 1
            AND COALESCE(a.n3_count, 0) = 0
            THEN 'Observateur'
          WHEN COALESCE(a.n3_count, 0) >= 2
            THEN 'Pilier'
          WHEN COALESCE(a.n2_count, 0) >= 2
            OR COALESCE(a.n3_count, 0) = 1
            THEN 'Contributeur'
          ELSE NULL -- unreachable: the branches above exhaust every possible n1/n2/n3 combination
        END AS segment,
        CASE
          WHEN COALESCE(s.nb_sessions, 0) <= 1
            AND COALESCE(a.n1_count, 0) + COALESCE(a.n2_count, 0) + COALESCE(a.n3_count, 0) = 0
            THEN NULL
          WHEN COALESCE(a.n1_count, 0) + COALESCE(a.n2_count, 0) + COALESCE(a.n3_count, 0) = 0
            THEN CASE
              WHEN uat.user_id IS NOT NULL THEN 'Dormant'
              ELSE 'À activer'
            END
          ELSE NULL
        END AS sub_segment
      FROM all_users u
      LEFT JOIN user_actions a           ON u.user_id = a.user_id
      LEFT JOIN user_actions_alltime uat ON u.user_id = uat.user_id
      LEFT JOIN user_sessions s          ON u.user_id = s.user_id
    SQL
  end

  def self.eligibility_clause(as_of_sql, eligibility)
    case eligibility
    when :last_sign_in_at
      "last_sign_in_at >= #{as_of_sql}::date - INTERVAL '30 days'"
    when :login_histories
      <<~SQL.strip
        EXISTS (
          SELECT 1 FROM login_histories lh
          WHERE lh.user_id = users.id
            AND lh.connected_at >= #{as_of_sql}::date - INTERVAL '30 days'
            AND lh.connected_at < #{as_of_sql}::date + INTERVAL '1 day'
        )
      SQL
    else
      raise ArgumentError, "unknown eligibility mode: #{eligibility.inspect}"
    end
  end
  private_class_method :eligibility_clause
end
