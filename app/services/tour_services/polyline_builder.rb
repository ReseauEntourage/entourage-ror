module TourServices
  class PolylineBuilder
    def initialize(tour:)
      @tour = tour
    end

    def polyline
      coordinates = tour.tour_points.select("latitude, longitude").map do |tour_point|
        {lat: tour_point.latitude, long: tour_point.longitude}
      end

      coordinates.each_slice(max_point).map do |sub_tour|
        response = GoogleMap::SnapToRoadRequest.new.perform(coordinates: sub_tour)
        response.coordinates_only
      end.flatten
    end

    def max_point
      99
    end

    private
    attr_reader :tour
  end
end