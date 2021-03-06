require 'cmath'

module TourServices
  class TourSimplifier
    R=6371.0

    def initialize(tour:)
      @tour = tour
    end

    def simplified_points
      original_points = tour.tour_points.ordered
      return original_points if original_points.count <= 10

      points = original_points.map {|tp| {x: R*CMath.cos(tp.latitude)*CMath.cos(tp.longitude),
                                           y: R*CMath.cos(tp.latitude)*CMath.sin(tp.longitude),
                                           id: tp.id}}
      tolerance = 1
      high_quality = true
      simplified_points = SimplifyRb.simplify(points, tolerance, high_quality)
      original_points.where(id: simplified_points.map {|point| point[:id]})
    end

    private
    attr_reader :tour
  end
end
