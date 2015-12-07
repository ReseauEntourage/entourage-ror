class SnapToRoadPolylineJob < ActiveJob::Base

  def perform(tour_id)
    tour = Tour.find(tour_id)
    builder = TourServices::PolylineBuilder.new(tour: tour)
    builder.polyline.each do |coordinate|
      tour.snap_to_road_tour_points.create(longitude: coordinate[:long],
                                            latitude: coordinate[:lat])
    end
  end
end