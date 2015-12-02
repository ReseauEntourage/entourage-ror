class TourPresenter
  delegate :id,
           :tour_type, to: :tour

  def initialize(tour:)
    @tour = tour
  end

  def snap_to_road_points
    TourBuilders::PolylineBuilder.new(tour: tour).polyline
  end

  private
  attr_reader :tour
end