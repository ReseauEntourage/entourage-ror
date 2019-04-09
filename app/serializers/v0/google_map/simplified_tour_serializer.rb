module V0
  module GoogleMap
    class SimplifiedTourSerializer < GoogleMap::TourSerializer
      def coordinates(tour)
        tour.simplified_tour_points.map { |point| [point.longitude, point.latitude] }
      end
    end
  end
end
