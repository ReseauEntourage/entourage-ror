module TourPointsServices
  class TourPointsSimplifier
    TOLERANCE=0.0003

    def initialize(tour_id:)
      @tour_id = tour_id
    end

    def simplified_tour_points clear_cache: false
      cache_key = "entourage:tours:#{tour_id}:tour_points"

      if clear_cache
        $redis.del(cache_key)
        cached_points = nil
      else
        cached_points = $redis.get(cache_key)
      end

      if cached_points.present?
        points = JSON.parse(cached_points)
      else
        pg_result = ApplicationRecord.connection.execute(sql)
        points = pg_result.map { |point| format_point(point) }
        # see: config/initializers/pg_result_clear.rb
        pg_result.clear
        $redis.set(cache_key, points.to_json)
      end

      points
    end

    private
    attr_reader :tour_id

    def format_point point
      point.each_pair { |k, v| point[k] = v.to_f }
    end

    def sql
      <<-SQL
      SELECT ST_X((result.points).geom) AS latitude, ST_Y((result.points).geom) AS longitude
      FROM (
        SELECT ST_DumpPoints(simplified_path.simplifiedLine) AS points
        FROM (
          SELECT ST_Simplify(ST_MakeLine(path.point), #{TOLERANCE}) as simplifiedLine
          FROM (
            SELECT ST_SetSRID(ST_MakePoint(latitude, longitude),4326) AS point
            FROM tour_points
            WHERE tour_id=#{tour_id}
            ORDER BY passing_time ASC
          ) as path
        ) simplified_path
      ) result
      SQL
    end
  end
end
