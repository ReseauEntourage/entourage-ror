class SimplifyTourPointsJob < ActiveJob::Base

  def perform(tour_id, should_send_mail=false)
    tour = Tour.find(tour_id)
    tour_points = TourPointsServices::TourPointsSimplifier.new(tour_id: tour_id).simplified_tour_points

    $redis.set("entourage:tours:#{tour.id}:tour_points", tour_points.to_json, {ex: 7 * 24 * 3600})

    tour.simplified_tour_points.destroy_all
    tour_points.each_with_index do |point, i|
      tour.simplified_tour_points.create(longitude: point["longitude"], latitude: point["latitude"], created_at: tour.created_at+i.seconds)
    end

    MemberMailer.tour_report(tour).deliver_later if should_send_mail
  end
end