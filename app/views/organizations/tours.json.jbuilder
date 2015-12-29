json.type "FeatureCollection"
json.features do
  current = 0
  json.array!(@presenters) do |presenter|
    current+=1
    json.type "Feature"
    json.properties do
      json.tour_type presenter.tour_type
      json.color TourPresenter.color(total: @presenters.count, current: current)
    end
    json.geometry do
      json.type "LineString"
      json.coordinates do
        json.array!(presenter.tour_points) do |coordinate|
          json.array!([coordinate[:long], coordinate[:lat]])
        end
      end
    end
  end
end
