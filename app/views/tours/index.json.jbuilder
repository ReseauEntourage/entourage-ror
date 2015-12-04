json.tours do
  json.array!(@presenters) do |presenter|
    json.id presenter.id
    json.tour_type presenter.tour_type
    json.status presenter.status
    json.vehicle_type presenter.vehicle_type
    json.start_time  presenter.start_time
    json.end_time  presenter.end_time
    json.organization_name presenter.organization_name
    json.organization_description presenter.organization_description
    json.tour_points do
      json.array!(presenter.snap_to_road_points) do |coordinates|
        json.latitude coordinate[:lat]
        json.longitude coordinate[:long]
        json.passing_time presenter.start_time
      end
    end
  end
end
