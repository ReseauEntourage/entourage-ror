class SimplifyTourPointsJob < ActiveJob::Base
  def perform(tour_id)
    tour = Tour.find(tour_id)
    simplified_points = TourServices::TourSimplifier.new(tour: tour).simplified_points
    simplified_points.each do |point|
      tour.simplified_tour_points.create(longitude: point.longitude, latitude: point.latitude)
    end
  end
end