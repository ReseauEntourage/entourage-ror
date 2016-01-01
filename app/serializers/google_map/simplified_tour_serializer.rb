module GoogleMap
  class SimplifiedTourSerializer < GoogleMap::TourSerializer
    def coordinates
      object.simplified_tour_points.map do |point|
        [point.longitude, point.latitude]
      end
    end
  end
end