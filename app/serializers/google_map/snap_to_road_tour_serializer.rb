module GoogleMap
  class SnapToRoadTourSerializer < GoogleMap::TourSerializer
    def coordinates
      object.snap_to_road_tour_points.map do |point|
        [point.longitude, point.latitude]
      end
    end
  end
end