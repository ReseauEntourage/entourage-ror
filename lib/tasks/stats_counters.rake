namespace :db do
  namespace :backfill do
    desc "Backfill users.entourages_count/actions_count/outings_count/neighborhoods_count"
    task stats_counters: :environment do
      connection = ActiveRecord::Base.connection

      puts 'Backfilling entourages_count...'
      connection.execute(<<~SQL)
        UPDATE users
        SET entourages_count = sub.count
        FROM (
          SELECT user_id, count(*) AS count
          FROM entourages
          WHERE group_type != 'conversation'
          GROUP BY user_id
        ) sub
        WHERE users.id = sub.user_id
      SQL

      puts 'Backfilling actions_count...'
      connection.execute(<<~SQL)
        UPDATE users
        SET actions_count = sub.count
        FROM (
          SELECT join_requests.user_id, count(*) AS count
          FROM join_requests
          INNER JOIN entourages ON entourages.id = join_requests.joinable_id
          WHERE join_requests.joinable_type = 'Entourage'
            AND join_requests.status = 'accepted'
            AND entourages.group_type = 'action'
          GROUP BY join_requests.user_id
        ) sub
        WHERE users.id = sub.user_id
      SQL

      puts 'Backfilling outings_count...'
      connection.execute(<<~SQL)
        UPDATE users
        SET outings_count = sub.count
        FROM (
          SELECT join_requests.user_id, count(*) AS count
          FROM join_requests
          INNER JOIN entourages ON entourages.id = join_requests.joinable_id
          WHERE join_requests.joinable_type = 'Entourage'
            AND join_requests.status = 'accepted'
            AND entourages.group_type = 'outing'
          GROUP BY join_requests.user_id
        ) sub
        WHERE users.id = sub.user_id
      SQL

      puts 'Backfilling neighborhoods_count...'
      connection.execute(<<~SQL)
        UPDATE users
        SET neighborhoods_count = sub.count
        FROM (
          SELECT user_id, count(*) AS count
          FROM join_requests
          WHERE joinable_type = 'Neighborhood'
            AND status = 'accepted'
          GROUP BY user_id
        ) sub
        WHERE users.id = sub.user_id
      SQL

      puts 'Done.'
    end
  end
end
