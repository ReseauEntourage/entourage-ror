json.type "FeatureCollection"
json.features do
  json.array!(@presenters) do |presenter|
    json.type "Feature"
    json.properties do
      json.tour_type presenter.tour_type
    end
    json.geometry do
      json.type "LineString"
      json.coordinates do
        json.array!(presenter.simplified_tour_points) do |coordinate|
          json.array!([coordinate[:long], coordinate[:lat]])
        end
      end
    end
  end
end
