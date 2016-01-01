module GoogleMap
  class SnapToRoadTourSerializer < GoogleMap::TourSerializer
    def coordinates(tour)
      tour.snap_to_road_tour_points.map { |point| [point.longitude, point.latitude] }
    end
  end
end