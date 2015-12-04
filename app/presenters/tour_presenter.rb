class TourPresenter
  delegate :id,
           :tour_type,
           :status,
           :vehicle_type,
           :organization_name,
           :organization_description,
           to: :tour

  def initialize(tour:)
    @tour = tour
  end

  def snap_to_road_points
    tour.snap_to_road_tour_points.map {|point| [point.longitude, point.latitude]}
  end

  def start_time
    tour.tour_points.first.try(:passing_time)
  end

  def end_time
    tour.tour_points.last.try(:passing_time)
  end

  private
  attr_reader :tour
end