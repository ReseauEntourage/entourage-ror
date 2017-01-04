module TourPointsServices
  class TourPointsBuilder < Struct.new(:tour, :params, :fail_with)
    def create
      begin
        sql = "INSERT INTO tour_points (passing_time, latitude, longitude, tour_id, created_at, updated_at) VALUES #{values}"
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute(sql)
        end
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Received invalid tour points params. Tour_id : #{tour.id} , Tour points : #{params}"
        false
      end
    end

    private
    def values
      params_array.map do |p|
        values = sanitized_hash(p).values.join(",")
        "(#{values})"
      end.join(",")
    end

    def sanitized_hash(p)
      unless p["passing_time"]
        Rails.logger.error "Found nil passing time for tour : #{tour.id}"
        raise TourPointsServices::MissingPassingTimeError if fail_with==:fail_with_exception
        p["passing_time"] = now
      end
      {
        passing_time: "'#{p["passing_time"]}'",
        latitude: p["latitude"].to_s,
        longitude: p["longitude"].to_s,
        tour_id: tour.id,
        created_at: "'#{now}'",
        updated_at: "'#{now}'"
      }
    end

    def now
      DateTime.now.iso8601(3)
    end

    def params_array
      params.is_a?(Array) ? params : [params]
    end
  end

  class MissingPassingTimeError < StandardError; end
end