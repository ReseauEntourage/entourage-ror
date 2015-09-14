json.encounters do
  json.array!(@encounters) do |encounter|
    json.latitude encounter.latitude
    json.longitude encounter.longitude
  end
end
json.stats do
  json.encounter_count @encounter_count
  json.tour_count @tour_count
  json.tourer_count @tourer_count
end