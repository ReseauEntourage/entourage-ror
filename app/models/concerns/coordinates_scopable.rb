module CoordinatesScopable
  extend ActiveSupport::Concern

  included do
    scope :inside_perimeter, -> (latitude, longitude, travel_distance) {
      if latitude && longitude
        where("#{PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)} < ?", travel_distance)
      end
    }
    scope :order_by_distance_from, -> (latitude, longitude) {
      if latitude && longitude
        order(PostgisHelper.distance_from(latitude, longitude, table_name.to_sym))
      end
    }
  end
end
