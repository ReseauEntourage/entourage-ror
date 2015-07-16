  json.tours do
    json.array!(@tours) do |tour|
      json.id tour.id
      json.type tour.tour_type
      json.tour_points do
        json.array!(tour.tour_points) do |tour_point|
          json.latitude tour_point.latitude
          json.longitude tour_point.longitude
          json.passing_time tour_point.passing_time
        end
      end
    end
  end