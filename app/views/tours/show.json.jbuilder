json.tour do
  json.id @tour.id
  json.tour_type @tour.tour_type
  json.status @tour.status
  json.vehicle_type @tour.vehicle_type
  json.tour_points do
    json.array!(@tour.tour_points) do |tour_point|
      json.latitude tour_point.latitude
      json.longitude tour_point.longitude
      json.passing_time tour_point.passing_time
    end
  end
end
