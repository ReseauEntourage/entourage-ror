module TourPointsServices
  class TourPointsSimplifier
    TOLERANCE=0.001

    def initialize(tour_id:)
      @tour_id = tour_id
    end

    def simplified_tour_points
      ActiveRecord::Base.connection.execute(sql)
    end

    private
    attr_reader :tour_id

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