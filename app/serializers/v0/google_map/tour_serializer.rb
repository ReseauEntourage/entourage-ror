module V0
  module GoogleMap
    class TourSerializer
      def initialize(tours:)
        @tours = tours
      end

      def to_json
        {
            type: "FeatureCollection",
            features: features
        }
      end

      private
      attr_reader :tours

      def features
        tours.each_with_index.map do |tour, index|
          {
              type: "Feature",
              properties: properties(tour, index),
              geometry: geometry(tour)
          }
        end
      end

      def properties(tour, index)
        {
            tour_type: tour.tour_type,
            color: TourPresenter.color(total: tours.count, current: index)
        }
      end

      def geometry(tour)
        {
            type: "LineString",
            coordinates: coordinates(tour)
        }
      end

      def coordinates(tour)
        tour.tour_points.map { |point| [point.longitude, point.latitude] }
      end
    end
  end
end
