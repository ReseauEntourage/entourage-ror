class SimplifyTourPointsJob < ActiveJob::Base
  def perform(tour_id)
    tour = Tour.find(tour_id)
    simplified_points = TourServices::TourSimplifier.new(tour: tour).simplified_points
    tour.tour_points.where("id NOT IN (?)", simplified_points.map(&:id)).delete_all
  end
end