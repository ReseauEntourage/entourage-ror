class SimplifyTourPointsJob < ActiveJob::Base
  def perform(tour_id, should_send_mail=false)
    tour = Tour.find(tour_id)
    tour.simplified_tour_points.destroy_all
    simplified_points = TourServices::TourSimplifier.new(tour: tour).simplified_points
    simplified_points.each do |point|
      tour.simplified_tour_points.create(longitude: point.longitude, latitude: point.latitude, created_at: point.passing_time)
    end

    points = tour.simplified_tour_points.ordered
    json = ActiveModel::ArraySerializer.new(points, each_serializer: ::V1::TourPointSerializer).to_json
    $redis.set("entourage:tours:#{tour.id}:tour_points", json, {ex: 7 * 24 * 3600})

    MemberMailer.tour_report(tour).deliver_later if should_send_mail
  end
end