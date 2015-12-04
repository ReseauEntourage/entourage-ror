module TourBuilders
  class PolylineBuilder
    def initialize(tour:)
      @tour = tour
    end

    def polyline
      coordinates = tour.tour_points.select("latitude, longitude").map do |tour_point|
        {lat: tour_point.latitude, long: tour_point.longitude}
      end

      #FIXME: Support for more than 100 points
      coordinates = coordinates.take(99)

      response = GoogleMap::SnapToRoadRequest.new.perform(coordinates: coordinates)
      response.coordinates_only
    end

    private
    attr_reader :tour
  end
end