json.type "FeatureCollection"
json.features do
  json.array!(@latest_tours) do |tour|
    json.type "Feature" 
    json.properties do
      json.type tour.tour_type
      json.color "blue"
    end
    json.geometry do 
      json.type "LineString"
      json.coordinates do
        json.array!(tour.tour_points) do |tour_point|
          json.array!([tour_point.longitude, tour_point.latitude])
        end
      end
    end
  end
end





