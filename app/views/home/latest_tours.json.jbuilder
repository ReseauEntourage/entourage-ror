json.type "FeatureCollection"
json.features do
  json.array!(@latest_tours) do |tour|
    json.type "Feature" 
    json.properties do
      json.type tour.tour_type
      json.color "blue"
    end
    json.coordinates do 
      json.array!(tour.tour_points) do |tour_point|
        json.array!([tour_point.latitude, tour_point.longitude])
      end
    end
  end
end
