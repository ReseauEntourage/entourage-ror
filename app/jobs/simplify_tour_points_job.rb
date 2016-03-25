class SimplifyTourPointsJob < ActiveJob::Base
  def perform(tour_id, should_send_mail=false)
    tour = Tour.find(tour_id)
    tour.simplified_tour_points.destroy_all
    simplified_points = TourServices::TourSimplifier.new(tour: tour).simplified_points
    simplified_points.each do |point|
      tour.simplified_tour_points.create(longitude: point.longitude, latitude: point.latitude, created_at: point.passing_time)
    end

    MemberMailer.tour_report(tour).deliver_later if should_send_mail
  end
end