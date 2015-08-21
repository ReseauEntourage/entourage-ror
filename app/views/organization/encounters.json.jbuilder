json.type "FeatureCollection"
json.features do
  json.array!(@encounters) do |encounter|
    json.type "Feature"
    json.properties do
      json.tour_type encounter.tour.tour_type
    end
    json.geometry do
      json.type "Point"
      json.coordinates do
        json.array!([encounter.longitude, encounter.latitude])
      end
    end
  end
end
