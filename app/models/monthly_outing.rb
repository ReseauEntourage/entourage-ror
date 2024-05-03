class MonthlyOuting < ApplicationRecord
  include CoordinatesScopable

  # Computes number of instances in every perimeter from 1 to 100km
  scope :count_by_distance_band, -> (latitude, longitude) {
    select(Arel.sql("FLOOR(#{PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)}) + 1 as distance_band, COUNT(*) as count"))
      .inside_perimeter(latitude, longitude, 100)
      .group(Arel.sql("FLOOR(#{PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)}) + 1"))
      .order("distance_band")
  }

  class << self
    def distance_bands latitude, longitude
      MonthlyOuting.count_by_distance_band(latitude, longitude)
        .map do |mo|
          [mo.distance_band, mo.count]
        end.to_h
    end

    # agregates distance bands to 1..100
    def monthly_averages latitude, longitude
      bands = distance_bands(latitude, longitude)

      final_hash = {}
      cumulative_sum = 0

      (1..100).each do |index|
        cumulative_sum += (bands[index.to_f] / 12.0) if bands[index.to_f]
        final_hash[index.to_f] = cumulative_sum
      end

      final_hash
    end
  end
end
