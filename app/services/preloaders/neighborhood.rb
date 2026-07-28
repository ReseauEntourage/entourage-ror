module Preloaders
  module Neighborhood
    def self.preload_future_outings_count(neighborhoods)
      return if neighborhoods.empty?

      ids = neighborhoods.map(&:id)
      conn = ActiveRecord::Base.connection

      rows = conn.execute(<<~SQL)
        SELECT ne.neighborhood_id, COUNT(DISTINCT e.id) AS count
        FROM neighborhoods_entourages ne
        INNER JOIN entourages e ON e.id = ne.entourage_id
        WHERE ne.neighborhood_id IN (#{ids.map(&:to_i).join(',')})
          AND e.group_type = 'outing'
          AND e.status IN ('open', 'full')
          AND e.metadata->>'ends_at' > NOW()::text
        GROUP BY ne.neighborhood_id
      SQL

      count_map = rows.each_with_object({}) { |row, h| h[row['neighborhood_id'].to_i] = row['count'].to_i }
      neighborhoods.each { |n| n.preloaded_future_outings_count = count_map[n.id] || 0 }
    end
  end
end
